#!/bin/bash
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_VIM="${DIR}"/../vim/.project.vim

echo content of \".project.vim\":
cat $PROJECT_VIM
echo

ln -sv $PROJECT_VIM "${DIR}"/../impala/src/
ln -sv $PROJECT_VIM "${DIR}"/../thorin/src/

echo
echo "include this in your \"~¸vimrc\" to automatically source the \".project.vim\":"
echo "if filereadable(\".project.vim\")"
echo "    source .project.vim"
echo "endif"
