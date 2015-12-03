#!/bin/sh
-set eu

if [ -z "$1" ]; then
    echo "Please supply a directory to install cmake!"
    exit 1
fi

wget https://cmake.org/files/v3.4/cmake-3.4.1-Linux-x86_64.sh
sed -i '/interactive=TRUE/c\interactive=FALSE' cmake-3.4.1-Linux-x86_64.sh
chmod +x cmake-3.4.1-Linux-x86_64.sh
./cmake-3.4.1-Linux-x86_64.sh --prefix=$1
rm cmake-3.4.1-Linux-x86_64.sh
