IMAGE=$1
DEFAULT_ACTION="N"

is_true() {
    case $1 in 
        "y"|"Y"|"a"|"A"|"Yes"|"yes")
            echo 1
            ;;
        *)
            echo 0
            ;;
    esac
}

usage() {
    echo "Usage:"
    echo -e "\t$(basename $0) NAME[:TAG]"
}

if [ $# -eq 1 ]; then
    [ "$1" == "-h" -o "$1" == "--help" ] && usage && exit 0
else
    usage
fi

registry=${IMAGE%%/*}
IMAGE=${IMAGE#*/}

repo=${IMAGE%%/*}
image=${IMAGE##*/}
tag=${IMAGE##*:}


if [ "$repo" == "$image" ]; then
    repo=library
fi

if [ "$tag" == "$IMAGE" ]; then
    tag=latest
fi

uri="$registry/v1/repositories/$repo/${image%%:*}/tags/$tag"

#:echo $uri

id=$(curl -X GET $uri 2> /dev/null)

[ -z "$id" ] && echo "Image does not exist" && exit 1
echo -n "Do you really want to untag $id? [y/N]: "
read action

[ -z "$action" ] && action=$DEFAULT_ACTION

if [ `is_true $action` == "1" ]; then 
    res=$(curl -X DELETE $uri 2> /dev/null)
    if [ "$res" == "true" ]; then
        echo "Image $repo/${image%%:*}:$tag removed from $registry"
    fi

fi

