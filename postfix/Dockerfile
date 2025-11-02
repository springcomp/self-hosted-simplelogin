# STAGE 0: use base image from Docker Hub and upgrade the existing packages
# ================================
ARG IMAGE_TAG="${IMAGE_TAG:-3.22}"
FROM alpine:${IMAGE_TAG} AS base

RUN apk --no-cache upgrade --purge

# STAGE 1: copy contents of the original base image to a new image so we don't have overlapping files in layers
# ================================
FROM scratch AS alpine
COPY --from=base / /

# STAGE 2: postfix
# ================================
FROM alpine AS postfix

# install dependencies
RUN apk --no-cache add postfix postfix-pgsql \
  && mkdir -p /templates /etc/postfix/conf.d

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY templates /templates/
COPY conf.d /etc/postfix/conf.d/

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/sbin/postfix", "start-fg"]
