#!/bin/sh -e

# Author: Patrice Ferlet <metal3d@gmail.com>
# License: MIT

[ "$PLUGIN_BUILDER" == "" ] && echo "You must set BUILDER paramter in settings" && exit 1
[ "$PLUGIN_TARGET" == "" ] && echo "You must set image target in settings" && exit 1

# if not target given, use "latest" tag per default
[ "$PLUGIN_TARGET" == "" ] && PLUGIN_TARGET="latest"

OPTS=""
if [ "$PLUGIN_INSECURE" == "true" ] && [ "$PLUGIN_REGISTRY" != "" ]; then
    OPTS=' --insecure-registry='$PLUGIN_REGISTRY
fi

# build s2i options
S2IOPTS=""
if [ "$PLUGIN_INCREMENTAL" == "true" ]; then
    S2IOPTS="--incremental"
fi

# Docker daemon checker
RETVAL="ko"
checkdocker(){
    res=$(echo -e "GET /version HTTP/1.0\r\n" | nc -U /var/run/docker.sock 2>/dev/null)
    echo "$res" | grep "Platform" && RETVAL="ok" || :
}

# Launching Docker
nohup dockerd -s overlay2 $OPTS  </dev/null >/dev/null 2>&1 &

# Wait for docker daemon
echo -e "Waiting for docker daemon"

COUNT=0
checkdocker || :
until [ $RETVAL == "ok" ]; do
    sleep 1
    COUNT=$((COUNT+1))
    [ $COUNT -gt 10 ] && echo "Docker cannot start" && exit 1
    checkdocker || :
done
echo

echo "Docker daemon is ready, building..."

# try to login if needed
if [ "${PLUGIN_USERNAME}" != "" ] && [ "${PLUGIN_PASSWORD}" != "" ]; then
    echo "Login to registry..."
    docker login $PLUGIN_REGISTRY --username "$PLUGIN_USERNAME" --password "$PLUGIN_PASSWORD"
fi

# build DRONE env
echo "Building..."
set -x
target=${RANDOM}-${RANDOM}-${RANDOM}-${RANDOM}
s2i build ${DRONE_WORKSPACE_BASE} $S2IOPTS --context-dir=${PLUGIN_CONTEXT-./} ${PLUGIN_BUILDER} ${target} --keep-symlinks --env=DRONE=true || exit 1

# tag the built image to the given tags
for tag in ${PLUGIN_TAGS//,/" "}; do
    docker tag ${target} $PLUGIN_TARGET:${tag}
done
set +x

# push tag if wanted
if [ "$PLUGIN_PUSH" == "true" ]; then
    echo "Pushing $PLUGIN_TARGET"

    for tag in ${PLUGIN_TAGS//,/" "}; do
        docker push ${PLUGIN_TARGET}:${tag} || exit 1
    done
    echo "Pushed"
fi

set -x
docker system prune -f || :

exit 0
