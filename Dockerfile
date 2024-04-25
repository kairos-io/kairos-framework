ARG SECURITY_PROFILE=generic


# Backport for kairos 3.0.x
# Fixes ssh user missing
# Fixes hooks in uki install
FROM quay.io/kairos/packages:kairos-agent-system-2.8.12 AS kairos-agent
FROM quay.io/kairos/packages:kairos-agent-fips-2.8.12 AS kairos-agent-fips

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

FROM base AS fips
RUN luet install -y --config repositories.yaml --system-target /framework \
    fips/kcrypt \
    fips/kcrypt-challenger \
    fips/immucore \
    fips/kairos-agent
COPY --from=kairos-agent-fips / /framework/

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
