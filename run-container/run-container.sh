#!/usr/bin/bash

#We need /run and /tmp volumes for fedora, cgroup is needed always
DEFAULT_VOLUMES="-v /sys/fs/cgroup:/sys/fs/cgroup -v /var/log/journal:/var/log/journal -v /run -v /tmp"
#We need to tell systemd that it runs in Docker
DEFAULT_ENVS="-e container=docker"
DEFAULT_CMD="/usr/sbin/init"
DEFAULT_OPTS="-it"
DEFAULT_NAME="test"

VOLUMES=${DEFAULT_VOLUMES}

IMAGE=$1
[ -z "${IMAGE}" ] && echo "Expecting image name" && exit 1

#Prepare machine-id mount
MACHINE_FILE=$(mktemp /tmp/container-XXXXX)
echo ${MACHINE_FILE}
VOLUMES="${VOLUMES} -v ${MACHINE_FILE}:/etc/machine-id"

#Create a container
ID=$(docker create --name ${DEFAULT_NAME} ${DEFAULT_OPTS} ${VOLUMES} ${DEFAULT_ENVS} ${IMAGE} ${DEFAULT_CMD})

#systemd expects machine-id to be 32 B
shortID=$(echo ${ID} |  cut -c1-32)

#Set machine-id
echo $shortID > ${MACHINE_FILE}


#Start the container
docker start $ID

