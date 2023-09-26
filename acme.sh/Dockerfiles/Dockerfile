# STAGE 0: docker:cli
# ================================
FROM docker:cli AS base
RUN apk --no-cache upgrade --purge

# STAGE 1: copy contents of the original base image to a new image so we don't have overlapping files in layers
# ================================
FROM scratch AS alpine
COPY --from=base / /
CMD ["/bin/sh"]

# STAGE 2: acme-official/acme.sh
# ================================
FROM alpine as acme.sh

# install dependencies
RUN apk --no-cache add openssl curl socat

# cache busting argument
ARG ACME_VERSION

# install acme.sh from the latest version available
RUN apk --no-cache add jq \
 && ACME_VERSION="$(if [ -z "${ACME_VERSION}" ]; then wget -q -O - https://api.github.com/repos/acmesh-official/acme.sh/releases/latest | jq -r .tag_name; else echo "${ACME_VERSION}"; fi)" \
 && apk del jq \
 && mkdir -p /usr/local/bin/dnsapi \
 && curl -s "https://raw.githubusercontent.com/acmesh-official/acme.sh/${ACME_VERSION}/acme.sh" > /usr/local/bin/acme.sh \
 && curl -s "https://raw.githubusercontent.com/acmesh-official/acme.sh/${ACME_VERSION}/dnsapi/dns_azure.sh" > /usr/local/bin/dnsapi/dns_azure.sh \
 && chmod +x /usr/local/bin/acme.sh \
 && chmod +x /usr/local/bin/dnsapi/dns_azure.sh

ENTRYPOINT ["/usr/local/bin/acme.sh"]

# STAGE 3: private/acme.sh
# ================================
FROM acme.sh
WORKDIR /
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

