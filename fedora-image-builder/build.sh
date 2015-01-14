#!/bin/bash

set -x

VM_IMAGE=/tmp/fedora.img
NAME=fedora-rawhide-base
KICKSTART=https://git.fedorahosted.org/cgit/spin-kickstarts.git/plain/fedora-docker-base.ks
REPO=http://kojipkgs.fedoraproject.org/mash/rawhide/x86_64/os/

while [ -n "$1" ]; do
    case $1 in
        "--disk")
            shift
            VM_IMAGE=$1
            ;;
        "--name")
            shift
            NAME=$1
            ;;
        "--kickstart")
            shift
            KICKSTART=$1
            ;;
        "--repo")
            shift
            REPO=$1
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;

    esac
    shift
done

if ! [ -e "${KICKSTART}" ]; then
    TMP_DIR=$(mktemp -d /tmp/build-image-XXXXXX)
    pushd $TMP_DIR &> /dev/null
    curl -O ${KICKSTART} --write-out '%{http_code}\n' | grep -v ^404$ &> /dev/null
    CURL_OUT=$?
    popd &> /dev/null
    if [ ${CURL_OUT} -eq 0 ]; then
       KICKSTART=${TMP_DIR}/${KICKSTART##*/}
    else
       echo "Can't find kickstart file: ${KICKSTART}"
       exit 1
    fi
fi


u=$([ -n "$SUDO_USER" ] && echo $SUDO_USER || echo $USER)

virt-install --connect=qemu:///system \
-n ${NAME} \
-r 2048 \
--vcpus=2 \
--os-variant=fedora20 \
--accelerate \
-v \
-w bridge:virbr0 \
--disk path=${VM_IMAGE},size=3,format=qcow2 \
-l ${REPO} \
--nographics \
--network network:default \
--console pty \
--hvm \
--noreboot \
--initrd-inject=${KICKSTART} \
-x "ks=file:/${KICKSTART##*/} console=tty0 console=ttyS0,115200"
#-x "ks=file:/{KS_NAME} console=tty0 console=ttyS0,19200n8"


[ $? -eq 0 ] && virt-tar-out -a ${VM_IMAGE} / - | docker import - ${u}/${NAME} 

virsh destroy ${NAME}
virsh undefine ${NAME} --remove-all-storage



