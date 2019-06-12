#!/bin/sh -e

# Author: Patrice Ferlet <metal3d@gmail.com>
# License: MIT

[ "$PLUGIN_IMAGE" == "" ] && echo "You must set image paramter in settings" && exit 1
[ "$PLUGIN_TARGET" == "" ] && echo "You must set image target in settings" && exit 1

OPTS=""
if [ "$PLUGIN_INSECURE" == "true" ] && [ "$PLUGIN_REGISTRY" != "" ]; then
    OPTS=' --insecure-registry='$PLUGIN_REGISTRY
fi


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
    echo $RETVAL
    COUNT=$((COUNT+1))
    [ $COUNT -gt 10 ] && echo "Docker cannot start" && exit 1
    checkdocker || :
done
echo

echo "Docker daemon is ready, building..."
s2i build ${DRONE_WORKSPACE_BASE} $S2IOPTS --keep-symlinks --context-dir=${PLUGIN_CONTEXT-./} ${PLUGIN_IMAGE} ${PLUGIN_TARGET} || exit 1

# push ?
if [ "$PLUGIN_PUSH" == "true" ]; then
    echo "Pushing $PLUGIN_TARGET"
    docker push ${PLUGIN_TARGET} || exit 1
    echo "Image pushed"
fi

docker system prune -f || :

exit 0
