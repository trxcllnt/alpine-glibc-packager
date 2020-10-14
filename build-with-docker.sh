#!/bin/sh

RSA_KEY_PREFIX=jvasileff
#RSA_PRIVATE_KEY=___PRIVATE_KEY_FOR_$RSA_KEY_PREFIX___

set -eu

if [ -z "${RSA_PRIVATE_KEY:-}" ]; then
    printf "Enter private rsa key for ${RSA_KEY_PREFIX} followed by a newline: "
    RSA_PRIVATE_KEY=$(sed '/^$/q')
fi

if [ -z "${RSA_PRIVATE_KEY:-}" ]; then
    echo "error: RSA_PRIVATE_KEY not set"
    exit 1
fi

# Create Docker volumes
docker create --name input --volume /home/builder/package arm32v6/alpine:3.12 /bin/true
docker cp . input:/home/builder/package/
docker create --name output --volume /packages arm32v6/alpine:3.12 /bin/true
docker cp ${RSA_KEY_PREFIX}.rsa.pub output:/packages/

# Build packages
RSA_PRIVATE_KEY_NAME="${RSA_KEY_PREFIX}.rsa"
docker run --rm \
    --env RSA_PRIVATE_KEY="$RSA_PRIVATE_KEY" \
    --env REPODEST="/packages" \
    --volumes-from input \
    --volumes-from output \
    arm32v6/alpine:3.12 \
    /bin/sh -c "
	set -eu

        apk --no-cache add alpine-sdk
        adduser -G abuild -D builder
        chown -R builder:abuild /packages
        chown -R builder:abuild /home/builder/package

        cd /home/builder/package
        echo \"$RSA_PRIVATE_KEY\" > /tmp/\"$RSA_PRIVATE_KEY_NAME\"
        export PACKAGER_PRIVKEY=/tmp/\"$RSA_PRIVATE_KEY_NAME\"
        su builder -c 'abuild -r'"

# Test package installation
docker run --rm \
    --volumes-from output \
    arm32v6/alpine:3.12 /bin/sh -c "
           cp /packages/${RSA_KEY_PREFIX}.rsa.pub /etc/apk/keys/ \
        && apk -U add --no-progress --upgrade /packages/builder/armhf/*.apk"

# Extract packages
mkdir -p packages
docker cp output:/packages/builder packages/

# Remove Docker volumes (TODO always do this!)
docker rm input
docker rm output

