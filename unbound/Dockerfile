FROM mvance/unbound:1.22.0
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN apt-get update \
 && apt-get install -y curl dnsutils

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/unbound.sh"]
