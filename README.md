# About This Fork

This is a fork of sgerrand's
[alpine-pkg-glibc](https://github.com/sgerrand/alpine-pkg-glibc) project with
minimal changes to build Alpine Linux `glibc` apk packages for the `armhf`
(`arm32v6`) architecture, which is used by the Raspberry Pi Zero.

The `glibc` binaries used to build the apk packages are built by
[docker-glibc-armhf-builder](https://github.com/jvasileff/docker-glibc-armhf-builder).

To build, using an Arm based computer:

    echo "_YOUR_RSA_PUBLIC_KEY_" > _YOUR_RSA_KEY_NAME_.rsa.pub
    export RSA_KEY_PREFIX=_YOUR_RSA_KEY_NAME_
    export RSA_PRIVATE_KEY=_YOUR_RSA_PRIVATE_KEY_
    ./build-with-docker.sh

The upstream readme follows:

# alpine-pkg-glibc

[![CircleCI](https://circleci.com/gh/sgerrand/alpine-pkg-glibc/tree/master.svg?style=svg)](https://circleci.com/gh/sgerrand/alpine-pkg-glibc/tree/master) ![x86_64](https://img.shields.io/badge/x86__64-supported-brightgreen.svg)

This is the [GNU C Library](https://gnu.org/software/libc/) as a Alpine Linux package to run binaries linked against `glibc`. This package utilizes a custom built glibc binary based on the vanilla glibc source. Built binary artifacts come from https://github.com/sgerrand/docker-glibc-builder.

## Releases

See the [releases page](https://github.com/sgerrand/alpine-pkg-glibc/releases) for the latest download links. If you are using tools like `localedef` you will need the `glibc-bin` and `glibc-i18n` packages in addition to the `glibc` package.

## Installing

The current installation method for these packages is to pull them in using `wget` or `curl` and install the local file with `apk`:

    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk
    apk add glibc-2.32-r0.apk

### Please Note

:warning: The URL of the public signing key has changed! :warning:

Any previous reference to `https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub` should be updated with immediate effect to `https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub`.

## Locales

You will need to generate your locale if you would like to use a specific one for your glibc application. You can do this by installing the `glibc-i18n` package and generating a locale using the `localedef` binary. An example for en_US.UTF-8 would be:

    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-bin-2.32-r0.apk
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-i18n-2.32-r0.apk
    apk add glibc-bin-2.32-r0.apk glibc-i18n-2.32-r0.apk
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8
