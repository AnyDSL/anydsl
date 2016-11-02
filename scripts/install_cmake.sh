#!/bin/sh
set -eu

function usage {
    echo "usage: install_cmake.sh <install_dir>"
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

if [ -d $1 ]; then
    wget --no-check-certificate https://cmake.org/files/v3.4/cmake-3.4.1-Linux-x86_64.sh
    sed -i '/interactive=TRUE/c\interactive=FALSE' cmake-3.4.1-Linux-x86_64.sh
    chmod +x cmake-3.4.1-Linux-x86_64.sh
    ./cmake-3.4.1-Linux-x86_64.sh --prefix=$1
    rm cmake-3.4.1-Linux-x86_64.sh
else
    echo "$1 is not a directory"
    usage
    exit 1
fi
