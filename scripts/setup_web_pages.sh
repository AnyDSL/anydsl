#!/bin/bash
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"/..

git clone git@github.com:AnyDSL/anydsl.github.io
