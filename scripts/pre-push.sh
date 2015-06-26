#!/bin/bash
set -eu

local_branch="$(git rev-parse --abbrev-ref HEAD)"
revert=false

while read local_ref local_sha remote_ref remote_sha
do
    remote_branch=${remote_ref#refs/heads/}
    if [ "$remote_ref" != "$remote_branch" ]; then
        if [ "$remote_branch" == "master" ]; then
            if [ "$local_branch" != "master" ]; then
                git checkout master
                revert=true
            fi

            changes="$(git log origin/master..master)"
            if [ -z "$changes" ]; then
                continue;
            fi
            ../scripts/update.sh $1 $(git rev-parse HEAD)
        fi
    fi
done

if [ "$revert" == true ]; then
    git checkout "$local_branch"
fi
