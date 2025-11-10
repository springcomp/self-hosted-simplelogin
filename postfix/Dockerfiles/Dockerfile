# STAGE 0: use base image from Docker Hub and upgrade the existing packages
# ================================
ARG IMAGE_TAG="${IMAGE_TAG:-3.18}"
FROM alpine:${IMAGE_TAG} AS base

RUN apk --no-cache upgrade --purge

# STAGE 1: copy contents of the original base image to a new image so we don't have overlapping files in layers
# ================================
FROM scratch AS alpine
COPY --from=base / /
CMD ["/bin/sh"]

# STAGE 2: DH parameter generation
# ================================
FROM alpine AS dhparams

# Install OpenSSL for DH parameter generation
RUN apk --no-cache add openssl

# Copy and execute the RFC 7919 parameter generation script
COPY ./generate-rfc7919-dhparams.sh /tmp/generate-rfc7919-dhparams.sh
RUN chmod +x /tmp/generate-rfc7919-dhparams.sh \
 && /tmp/generate-rfc7919-dhparams.sh

# Generate legacy 512-bit DH params for compatibility (if needed)
RUN openssl dhparam -out /tmp/dh512.pem 512 \
 && chmod 644 /tmp/dh512.pem

# STAGE 3: postfix (final stage)
# ================================
FROM alpine AS postfix

# install dependencies
RUN apk --no-cache add postfix postfix-pgsql openssl

# Copy DH parameters from the dhparams stage
COPY --from=dhparams /tmp/ffdhe*.pem /etc/postfix/
COPY --from=dhparams /tmp/dh512.pem /etc/postfix/

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
