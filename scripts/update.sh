#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$DIR"
cd ..
cd "$1"

echo "Executing doxygen on $1"
doxygen doxyfile

cd ../anydsl.github.io
git pull
mkdir -p doxygen/"$1"
cp -R ../"$1"/html/* doxygen/"$1"/

git add doxygen/"$1"/*
git commit -m "updating doxygen for commit AnyDSL/$1@$2"
git push
