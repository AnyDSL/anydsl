#!/bin/bash
set -eu

function usage {
    echo "usage: install_ycomp.sh <install_dir>"
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

DIR="$(pwd)/$1"

if [ -d $1 ]; then
    wget http://pp.ipd.kit.edu/firm/download/yComp-1.3.19.zip -O "${DIR}/ycomp.zip"
    unzip "${DIR}/ycomp.zip" -d "${DIR}"
    ycomp="${DIR}/yComp-1.3.19/ycomp"
    chmod u+x ${ycomp}
    echo "now put \"${ycomp}\" in your path"
else
    echo "$1 is not a directory"
    usage
    exit 1
fi
