#!/bin/bash

set +x

function usage() {
    echo "Tool for building Docker base images"
    echo "$0 --kickstart file.ks --disk tmpvm.img --name my-image ..."
    echo "  --kickstart               Path to KS file which defines your new image"
    echo "  --installroot             virt-insall's location option"
    echo "  --repo                    Comma (,) separated list of repos you want to use in KS file"
    echo "  --name                    Name of the created image - \$USER/\$NAME"
    echo "  --disk                    Path to a file which will be temporarily used as a VM disk"
    echo "  --keep-vm [vm|image]      Don't remove VM (vm) or the VM image (image) after build"
    echo "  --skip-docker             Skip docker import"
    echo "  --docker-build            Run docker build cmd on Dockerfile stored in KS directory"
    echo "  --docker-save             Run docker save cmd"
}

_() {
    $QUIET && return
    echo -e "\033[1m("$*")\033[0m"
}

VM_IMAGE=/tmp/fedora.img
NAME=fedora-rawhide-base
KICKSTART=https://git.fedorahosted.org/cgit/spin-kickstarts.git/plain/fedora-docker-base.ks
INSTALLROOT=http://kojipkgs.fedoraproject.org/mash/rawhide/x86_64/os/
DOCKER_IMPORT=true
DOCKER_BUILD=false
DOCKER_SAVE=false
DOCKER_SAVE_DIR=builds
KEEP_VM=
REPO=
KERNEL=
INITRD=
BOOT=""
QUIET=false

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
        "--docker-build")
            DOCKER_BUILD=true
            ;;
        "--docker-save")
            DOCKER_SAVE=true
            ;;
        "-h")
            usage
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            usage
            exit 1
            ;;

    esac
    shift
done



u=$([ -n "$SUDO_USER" ] && echo $SUDO_USER || echo $USER)

KS_DIR=$(dirname ${KICKSTART})
TMP_DIR=$(mktemp -d /tmp/build-image-XXXXXX)
_ "Using temp directory ${TMP_DIR}"
if ! [ -e "${KICKSTART}" ]; then
    
    pushd $TMP_DIR &> /dev/null
    curl -O ${KICKSTART} --write-out '%{http_code}\n' | grep -v ^404$ &> /dev/null
    CURL_OUT=$?
    popd &> /dev/null
    if [ ${CURL_OUT} -eq 0 ]; then
       KICKSTART=${TMP_DIR}/${KICKSTART##*/}
    else
       _ "Can't find kickstart file: ${KICKSTART}"
       exit 1
    fi
else
    cp ${KICKSTART} ${TMP_DIR}
    KICKSTART=${TMP_DIR}/${KICKSTART##*/}
fi

if ${DOCKER_BUILD}; then
    if ! [ -e "${KS_DIR}/Dockerfile" ]; then
        _ "Could not find Dockerfile, won't run docker build."
        DOCKER_BUILD=false
    fi
    cp ${KS_DIR}/Dockerfile ${TMP_DIR}
    sed -i "s#@imagename@#${u}/${NAME}#" ${TMP_DIR}/Dockerfile

fi

[ -z "${REPO}" ] && REPO=${INSTALLROOT}

i=0
for repo in $(echo ${REPO} | tr "," "\n"); do
    replace="repo --name=build-$i --baseurl=${repo}"
    sudo sed -i "s#^%packages.*#${replace}\n&#" ${KICKSTART}
    i=$(( $i + 1 ))
done


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
[ $? -eq 0 ] && ${DOCKER_IMPORT} && ${DOCKER_BUILD} && docker build -t ${u}/${NAME}-build ${TMP_DIR}
if ${DOCKER_IMPORT} && ${DOCKER_SAVE}; then
    [ -d ${DOCKER_SAVE_DIR} ] || mkdir ${DOCKER_SAVE_DIR}
    if ${DOCKER_BUILD}; then
        docker save -o ${DOCKER_SAVE_DIR}/${u}-${NAME}-build.tar ${u}/${NAME}-build
    elif ${DOCKER_IMPORT}; then
        docker save -o ${DOCKER_SAVE_DIR}/${u}-${NAME}.tar ${u}/${NAME}
    else
        _ "No image to save"
    fi
fi

virsh destroy ${NAME}

if [ -n "${KEEP_VM}" ]; then 
    if [ ${KEEP_VM} == "image" ]; then
        virsh undefine ${NAME}
    elif [ ${KEEP_VM} == "vm" ]; then
        #TODO: Rewrite this..ugh
        _ "Keeping VM"
    fi
else
    virsh undefine ${NAME}  --remove-all-storage
fi
#virsh undefine ${NAME} # --remove-all-storage

_ "Find the KS $(${DOCKER_BUILD} && echo 'and Dockerfile') in ${TMP_DIR}"
${DOCKER_SAVE} && _ "Docker image saved to ${DOCKER_SAVE_DIR}/${u}-${NAME}.tar"

