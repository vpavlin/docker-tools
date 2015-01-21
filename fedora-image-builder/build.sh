#!/bin/bash

set -x

VM_IMAGE=/tmp/fedora.img
NAME=fedora-rawhide-base
KICKSTART=https://git.fedorahosted.org/cgit/spin-kickstarts.git/plain/fedora-docker-base.ks
INSTALLROOT=http://kojipkgs.fedoraproject.org/mash/rawhide/x86_64/os/
DOCKER_IMPORT=true
KEEP_VM=
REPO=
KERNEL=
INITRD=
BOOT=""

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
        "--installroot")
            shift
            INSTALLROOT=$1
            ;;
        "--repo")
            shift
            REPO=$1
            ;;
        "--kernel")
            shift
            KERNEL=$1
            ;;
        "--initrd")
            shift
            INITRD=$1
            ;;
        "--keep-vm")
            if ! [[ $2 =~ ^--* ]]; then
                shift
                KEEP_VM=$1
            else
                KEEP_VM="image"
            fi
            ;;
        "--skip-docker")
            DOCKER_IMPORT=false
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;

    esac
    shift
done

TMP_DIR=$(mktemp -d /tmp/build-image-XXXXXX)
if ! [ -e "${KICKSTART}" ]; then
    
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
else
    cp ${KICKSTART} ${TMP_DIR}
    KICKSTART=${TMP_DIR}/${KICKSTART##*/}
fi

[ -z "${REPO}" ] && REPO=${INSTALLROOT}

i=0
for repo in $(echo ${REPO} | tr "," "\n"); do
    replace="repo --name=build-$i --baseurl=${repo}"
    sudo sed -i "s#^%packages.*#${replace}\n&#" ${KICKSTART}
    i=$(( $i + 1 ))
done

u=$([ -n "$SUDO_USER" ] && echo $SUDO_USER || echo $USER)

[ -e "${KERNEL}" -a -e "${INITRD}" ] && BOOT="--boot kernel=${KERNEL},initrd=${INITRD}"

virt-install --connect=qemu:///system \
-n ${NAME} \
-r 2048 \
--vcpus=2 \
--os-variant=fedora20 \
--accelerate \
-v \
-w bridge:virbr0 \
--disk path=${VM_IMAGE},size=8,format=qcow2 \
-l ${INSTALLROOT} \
--nographics \
--network network:default \
--console pty \
--hvm \
--noreboot \
$BOOT \
--initrd-inject=${KICKSTART} \
-x "ks=file:/${KICKSTART##*/} console=tty0 console=ttyS0,115200"
#-x "ks=file:/{KS_NAME} console=tty0 console=ttyS0,19200n8"


[ $? -eq 0 ] && ${DOCKER_IMPORT} && virt-tar-out -a ${VM_IMAGE} / - | docker import - ${u}/${NAME} 

virsh destroy ${NAME}

if [ -n "${KEEP_VM}" ]; then 
    if [ ${KEEP_VM} == "image" ]; then
        virsh undefine ${NAME}
    elif [ ${KEEP_VM} == "vm" ]; then
        #TODO: Rewrite this..ugh
        echo "Keeping VM"
    fi
else
    virsh undefine ${NAME}  --remove-all-storage
fi
#virsh undefine ${NAME} # --remove-all-storage



