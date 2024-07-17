ARG SECURITY_PROFILE=generic
FROM quay.io/kairos/packages:luet-utils-0.35.2 AS luet
FROM quay.io/kairos/packages-arm64:luet-utils-0.35.2 AS luet-arm64

FROM alpine AS alpine-amd64
ENV LUET_NOLOCK=true
COPY --from=luet /usr/bin/luet /usr/bin/luet

FROM alpine AS alpine-arm64
ENV LUET_NOLOCK=true
COPY --from=luet-arm64 /usr/bin/luet /usr/bin/luet

# Common packages for all images
FROM alpine-${TARGETARCH} AS base
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

FROM base AS fips
RUN luet install -y --config repositories.yaml --system-target /framework \
    fips/kcrypt \
    fips/kcrypt-challenger \
    fips/immucore \
    fips/kairos-agent

# Final images
FROM ${SECURITY_PROFILE} AS post
RUN mkdir -p /framework/etc/kairos/
RUN luet database --system-target /framework get-all-installed --output /framework/etc/kairos/versions.yaml

# luet cleanup
RUN luet cleanup --system-target /framework
RUN rm -rf /framework/var/luet

FROM scratch AS final
ARG TARGETARCH
COPY repositories.yaml /etc/luet/luet.yaml
COPY --from=post /framework /
COPY --from=post /usr/bin/luet /usr/bin/luet
