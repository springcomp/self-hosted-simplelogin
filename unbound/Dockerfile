# Private Unbound image
# ================================
# Builds a thin wrapper around the upstream crazymax/unbound image so that
# the effective listener/module/identity/root-hints/timeout settings are
# source-controlled templates (see ./templates/) instead of an inline
# heredoc in postfix-compose.yaml. This preserves the no-host-bind-mount
# deployment model: templates are baked into the image and rendered into
# /config at container start by docker-entrypoint.sh.
ARG IMAGE_TAG="${IMAGE_TAG:-1.26.1}"
FROM crazymax/unbound:${IMAGE_TAG}

USER root

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY templates /templates/

RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
