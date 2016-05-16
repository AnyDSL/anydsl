#!/bin/bash
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"/..

git clone https://github.com/AnyDSL/anydsl.wiki.git
ln -sv "${DIR}/pre-commit-wiki.hook" "${DIR}/../anydsl.wiki/.git/hooks/pre-commit"
