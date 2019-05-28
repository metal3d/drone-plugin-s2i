FROM plugins/docker

ENV S2I_VERSION=1.1.14 \
    S2I_GITCOMMIT=874754de
RUN set -xe; \
    wget -O - https://github.com/openshift/source-to-image/releases/download/v${S2I_VERSION}/source-to-image-v${S2I_VERSION}-${S2I_GITCOMMIT}-linux-amd64.tar.gz | tar -C /usr/local/bin -zxf - ./s2i

RUN apk add netcat-openbsd

ADD s2ibuild.sh /usr/local/bin/s2ibuild.sh

ENTRYPOINT ["/usr/local/bin/dockerd-entrypoint.sh", "/usr/local/bin/s2ibuild.sh"]
