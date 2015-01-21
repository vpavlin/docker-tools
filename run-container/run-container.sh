#!/usr/bin/bash

#We need /run and /tmp volumes for fedora, cgroup is needed always
DEFAULT_VOLUMES="-v /sys/fs/cgroup:/sys/fs/cgroup -v /run -v /tmp"
#We need to tell systemd that it runs in Docker
DEFAULT_ENVS="-e container=docker"
DEFAULT_CMD="/usr/sbin/init"
DEFAULT_OPTS="-it"
DEFAULT_NAME="test"

VOLUMES=${DEFAULT_VOLUMES}

#Create a temp dir to store logs and machine-id
TMP_DIR=$(mktemp -d /tmp/container-XXXXX)
echo ${TMP_DIR}

#Prepare journal mount
LOG_DIR=${TMP_DIR}/logs
[ -d ${LOG_DIR} ] || mkdir ${LOG_DIR}
VOLUMES="${VOLUMES} -v ${LOG_DIR}:/var/log/journal"

#Prepare machine-id mount
MACHINE_FILE=${TMP_DIR}/machine-id
[ -e ${MACHINE_FILE} ] || touch ${TMP_DIR}/machine-id
VOLUMES="${VOLUMES} -v ${MACHINE_FILE}:/etc/machine-id"

IMAGE=$1
[ -z "${IMAGE}" ] && echo "Expecting image name" && exit 1

#Create a container
ID=$(docker create --name ${DEFAULT_NAME} ${DEFAULT_OPTS} ${VOLUMES} ${DEFAULT_ENVS} ${IMAGE} ${DEFAULT_CMD})

#systemd expects machine-id to be 32 B
shortID=$(echo ${ID} |  cut -c1-32)

#Set machine-id
echo $shortID > ${MACHINE_FILE}

#Add logs to host's /var/log/journal
mkdir ${LOG_DIR}/$shortID
ln -s ${LOG_DIR}/$shortID /var/log/journal/$shortID


#Start the container
docker start $ID

