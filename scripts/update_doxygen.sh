#!/bin/bash
set -eu

if [[ "$#" -ne 1 && "$#" -ne 2 ]]; then
    echo "usage: $0 (thorin | impala) [commit_sha1]" >& 2
    exit 1
fi


HERE=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$HERE"/../"$1"

echo "Executing doxygen on $1"
doxygen doxyfile

cd ../anydsl.github.io
git pull -s ours --no-edit
git rm -r doxygen/"$1"

mkdir -p doxygen/"$1"
cp -R ../"$1"/html/* doxygen/"$1"/

if [ -z ${2-} ]; then
    MESSAGE="bumping doxygen for AnyDSL/$1"
else
    MESSAGE="updating doxygen for commit AnyDSL/$1@$2"
fi

git add doxygen/"$1"/*
git commit -m "$MESSAGE"
git push
