ARG SECURITY_PROFILE=generic

FROM quay.io/kairos/packages:immucore-fips-0.1.17-2 AS immucore-fips
FROM quay.io/kairos/packages:immucore-system-0.1.17-2 AS immucore-system

FROM quay.io/kairos/packages:kairos-agent-system-2.5.1 AS kairos-agent
FROM quay.io/kairos/packages:kairos-agent-fips-2.5.1 AS kairos-agent-fips

FROM quay.io/kairos/packages:kcrypt-challenger-system-0.6.0-cve1 AS kcrypt-challenger
FROM quay.io/kairos/packages:kcrypt-challenger-fips-0.6.0-cve1 AS kcrypt-challenger-fips

FROM quay.io/kairos/packages:kcrypt-fips-0.7.0-cve1 AS kcrypt-fips
FROM quay.io/kairos/packages:kcrypt-system-0.7.0-cve1 AS kcrypt

FROM quay.io/luet/base:0.35.1 AS luet

# Common packages for all images
FROM alpine AS base
ENV LUET_NOLOCK=true
COPY --from=luet /usr/bin/luet /usr/bin/luet
COPY repositories.yaml /repositories.yaml
RUN luet install -y --config repositories.yaml --system-target /framework \
  dracut/immucore \
  dracut/kairos-network \
  dracut/kairos-sysext \
  system/suc-upgrade \
  system/grub2-efi \
  static/grub-config \
  static/kairos-overlay-files \
  initrd/alpine

FROM base AS generic
RUN luet install -y --config repositories.yaml --system-target /framework \
    system/kcrypt \
    system/kcrypt-challenger \
    system/immucore \
    system/kairos-agent
COPY --from=immucore-system / /framework/
COPY --from=kairos-agent / /framework/
COPY --from=kcrypt-challenger / /framework/
COPY --from=kcrypt / /framework/

FROM base AS fips
RUN luet install -y --config repositories.yaml --system-target /framework \
    fips/kcrypt \
    fips/kcrypt-challenger \
    fips/immucore \
    fips/kairos-agent
COPY --from=immucore-fips / /framework/
COPY --from=kairos-agent-fips / /framework/
COPY --from=kcrypt-challenger-fips / /framework/
COPY --from=kcrypt-fips / /framework/

# Final images
FROM ${SECURITY_PROFILE} AS post
RUN mkdir -p /framework/etc/kairos/
RUN luet database --system-target /framework get-all-installed --output /framework/etc/kairos/versions.yaml

# luet cleanup
RUN luet cleanup --system-target /framework
RUN rm -rf /framework/var/luet
RUN rm -rf /framework/var/cache

FROM scratch AS final
COPY repositories.yaml /etc/luet/luet.yaml
COPY --from=post /framework /
COPY --from=luet /usr/bin/luet /usr/bin/luet