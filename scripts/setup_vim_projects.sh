#!/bin/bash
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp ../vim/.project.vim ../impala/src/
cp ../vim/.project.vim ../thorin/src/
