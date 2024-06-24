ARG SECURITY_PROFILE=generic
ARG TARGETARCH=amd64


# Backport for kairos 3.0.x

# Bumps yip for user id reuse
# Fixes hooks in uki install
# kcrypt bump for: Trigger udev to populate disk info
FROM quay.io/kairos/packages:kairos-agent-system-2.8.21 AS kairos-agent-amd64
FROM quay.io/kairos/packages:kairos-agent-fips-2.8.21 AS kairos-agent-fips-amd64
FROM quay.io/kairos/packages-arm64:kairos-agent-system-2.8.21 AS kairos-agent-arm64
FROM quay.io/kairos/packages-arm64:kairos-agent-fips-2.8.21 AS kairos-agent-fips-arm64

# Adds sync calls before and after mounting
# Fixes mounting oem before running rootfs stage under uki
# Bumps yip for user id reuse
FROM quay.io/kairos/packages:immucore-fips-0.1.34 AS immucore-fips-amd64
FROM quay.io/kairos/packages:immucore-system-0.1.34 AS immucore-amd64
FROM quay.io/kairos/packages-arm64:immucore-fips-0.1.34 AS immucore-fips-arm64
FROM quay.io/kairos/packages-arm64:immucore-system-0.1.34 AS immucore-arm64

# Trigger udev to populate disk info
FROM quay.io/kairos/packages:kcrypt-fips-0.10.5 AS kcrypt-fips-amd64
FROM quay.io/kairos/packages:kcrypt-system-0.10.5 AS kcrypt-amd64
FROM quay.io/kairos/packages-arm64:kcrypt-fips-0.10.5 AS kcrypt-fips-arm64
FROM quay.io/kairos/packages-arm64:kcrypt-system-0.10.5 AS kcrypt-arm64

FROM quay.io/kairos/packages:kcrypt-challenger-system-0.7.0-1 AS kcrypt-challenger-amd64
FROM quay.io/kairos/packages:kcrypt-challenger-fips-0.7.0-1 AS kcrypt-challenger-fips-amd64
FROM quay.io/kairos/packages-arm64:kcrypt-challenger-system-0.7.0-2 AS kcrypt-challenger-amd64
FROM quay.io/kairos/packages-arm64:kcrypt-challenger-fips-0.7.0-2 AS kcrypt-challenger-fips-amd64

     
FROM quay.io/kairos/packages:luet-utils-0.35.2 AS luet-amd64
FROM quay.io/kairos/packages-arm64:luet-utils-0.35.2 AS luet-arm64


FROM alpine AS alpine-amd64
COPY --from=luet-amd64 /usr/bin/luet /usr/bin/luet

FROM alpine AS alpine-arm64
COPY --from=luet-arm64 /usr/bin/luet /usr/bin/luet

# Common packages for all images
FROM alpine-${TARGETARCH} AS base
ENV LUET_NOLOCK=true
COPY repositories.yaml /repositories.yaml
RUN luet install -y --config repositories.yaml --system-target /framework \
  dracut/kairos-network \
  dracut/kairos-sysext \
  system/suc-upgrade \
  static/grub-config \
  static/kairos-overlay-files \
  initrd/alpine

FROM base AS base-generic
RUN luet install -y --config repositories.yaml --system-target /framework \
    system/kcrypt \
    system/kcrypt-challenger \
    system/immucore \
    system/kairos-agent

FROM base-generic AS generic-amd64
COPY --from=kairos-agent-amd64 / /framework/
COPY --from=immucore-amd64 / /framework/
COPY --from=kcrypt-amd64 / /framework/
COPY --from=kcrypt-challenger-amd64 / /framework/

FROM base-generic AS generic-arm64
COPY --from=kairos-agent-arm64 / /framework/
COPY --from=immucore-arm64 / /framework/
COPY --from=kcrypt-arm64 / /framework/
COPY --from=kcrypt-challenger-arm64 / /framework/

FROM base AS base-fips
RUN luet install -y --config repositories.yaml --system-target /framework \
    fips/kcrypt \
    fips/kcrypt-challenger \
    fips/immucore \
    fips/kairos-agent

FROM base-fips AS fips-amd64
COPY --from=kairos-agent-fips-amd64 / /framework/
COPY --from=immucore-fips-amd64 / /framework/
COPY --from=kcrypt-fips-amd64 / /framework/
COPY --from=kcrypt-challenger-fips-amd64 / /framework/

FROM base-fips AS fips-arm64
COPY --from=kairos-agent-fips-arm64 / /framework/
COPY --from=immucore-fips-arm64 / /framework/
COPY --from=kcrypt-fips-arm64 / /framework/
COPY --from=kcrypt-challenger-fips-arm64 / /framework/

# Final images
FROM ${SECURITY_PROFILE}-${TARGETARCH} AS post
RUN mkdir -p /framework/etc/kairos/
RUN luet database --system-target /framework get-all-installed --output /framework/etc/kairos/versions.yaml

# luet cleanup
RUN luet cleanup --system-target /framework
RUN rm -rf /framework/var/luet

FROM scratch AS final-amd64
COPY --from=luet-amd64 /usr/bin/luet /usr/bin/luet

FROM scratch AS final-aarm64
COPY --from=luet-arm64 /usr/bin/luet /usr/bin/luet

FROM final-${TARGETARCH} AS final
COPY repositories.yaml /etc/luet/luet.yaml
COPY --from=post /framework /
