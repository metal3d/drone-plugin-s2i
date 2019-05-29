#!/bin/sh

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

checkdocker(){
    echo -e "GET /version HTTP/1.0\r\n" | nc -U /var/run/docker.sock 2>/dev/null | grep Platform 2>&1 1>/dev/null
    return $?
}

# Launching Docker
nohup dockerd -s overlay2 $OPTS  </dev/null >/dev/null 2>&1 &

COUNT=0
echo -e "Waiting for docker daemon "
sleep 3

checkdocker
until [ $? == 0 ]; do
    sleep 1
    COUNT=$((COUNT+1))
    [ $COUNT -gt 10 ] && exit 1
    echo -e "."
    checkdocker
done
echo

echo "Docker daemon is ready, building..."
s2i build ${DRONE_WORKSPACE_BASE} $S2IOPTS --context-dir=${PLUGIN_CONTEXT-./} ${PLUGIN_IMAGE} ${PLUGIN_TARGET} || exit 1

# push ?
if [ "$PLUGIN_PUSH" == "true" ]; then
    echo "Pushing $PLUGIN_TARGET"
    docker push ${PLUGIN_TARGET} || exit 1
    echo "Image pushed"
fi

exit 0
