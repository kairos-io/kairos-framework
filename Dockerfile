ARG SECURITY_PROFILE=generic


# Backport for kairos 3.0.x

# Bumps yip for user id reuse
# Fixes hooks in uki install
# kcrypt bump for: Trigger udev to populate disk info
FROM quay.io/kairos/packages:kairos-agent-system-2.8.20 AS kairos-agent
FROM quay.io/kairos/packages:kairos-agent-fips-2.8.20 AS kairos-agent-fips

# Adds sync calls before and after mounting
# Fixes mounting oem before running rootfs stage under uki
# Bumps yip for user id reuse
FROM quay.io/kairos/packages:immucore-fips-0.1.32 AS immucore-fips
FROM quay.io/kairos/packages:immucore-system-0.1.32 AS immucore

# Trigger udev to populate disk info
FROM quay.io/kairos/packages:kcrypt-fips-0.10.5 AS kcrypt-fips
FROM quay.io/kairos/packages:kcrypt-system-0.10.5 AS kcrypt

FROM quay.io/luet/base:0.35.1 AS luet

# Common packages for all images
FROM alpine AS base
ENV LUET_NOLOCK=true
COPY --from=luet /usr/bin/luet /usr/bin/luet
COPY repositories.yaml /repositories.yaml
RUN luet install -y --config repositories.yaml --system-target /framework \
  dracut/kairos-network \
  dracut/kairos-sysext \
  system/suc-upgrade \
  static/grub-config \
  static/kairos-overlay-files \
  initrd/alpine

FROM base AS generic
RUN luet install -y --config repositories.yaml --system-target /framework \
    system/kcrypt \
    system/kcrypt-challenger \
    system/immucore \
    system/kairos-agent
COPY --from=kairos-agent / /framework/
COPY --from=immucore / /framework/
COPY --from=kcrypt / /framework/

FROM base AS fips
RUN luet install -y --config repositories.yaml --system-target /framework \
    fips/kcrypt \
    fips/kcrypt-challenger \
    fips/immucore \
    fips/kairos-agent
COPY --from=kairos-agent-fips / /framework/
COPY --from=immucore-fips / /framework/
COPY --from=kcrypt-fips / /framework/

# Final images
FROM ${SECURITY_PROFILE} AS post
RUN mkdir -p /framework/etc/kairos/
RUN luet database --system-target /framework get-all-installed --output /framework/etc/kairos/versions.yaml

# luet cleanup
RUN luet cleanup --system-target /framework
RUN rm -rf /framework/var/luet

FROM scratch AS final
COPY repositories.yaml /etc/luet/luet.yaml
COPY --from=post /framework /
COPY --from=luet /usr/bin/luet /usr/bin/luet
