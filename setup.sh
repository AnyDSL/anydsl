#!/bin/bash
set -eu

COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo ">>> update meta project"
meta_out=$(git pull)
if [ "$meta_out" != "Already up-to-date." ]; then
    echo "meta project has been updated - I rerun the script"
    ./$0
    exit
fi

if [ ! -e config.sh ]; then
    echo "first configure your build:"
    echo "cp config.sh.template config.sh"
    echo "edit config.sh"
    exit -1
fi

source config.sh

CUR=`pwd`

function remote {
    if $HTTPS; then
        echo "https://github.com/$1"
    else
        echo "git@github.com:$1"
    fi
}

function clone_or_update {
    branch=${3:-master}
    if [ ! -e "$2" ]; then
        echo ">>> clone $1/$2 $COLOR_RED($branch)$COLOR_RESET"
        echo -e "git clone --recursive `remote $1/$2.git` --branch $branch"
        git clone --recursive `remote $1/$2.git` --branch $branch
    else
        cd $2
        echo -e ">>> pull $1/$2 $COLOR_RED($branch)$COLOR_RESET"
        git pull
        git checkout $branch
        cd ..
    fi
    mkdir -p "$2"/build/
}

# fetch sources
if [ "${LLVM-}" == true ] ; then
    mkdir -p llvm_build/

    if [ ! -e  "${CUR}/llvm" ]; then
        wget http://releases.llvm.org/4.0.1/llvm-4.0.1.src.tar.xz
        tar xf llvm-4.0.1.src.tar.xz
        rm llvm-4.0.1.src.tar.xz
        mv llvm-4.0.1.src llvm
        cd llvm/tools
        wget http://releases.llvm.org/4.0.1/cfe-4.0.1.src.tar.xz
        tar xf cfe-4.0.1.src.tar.xz
        rm cfe-4.0.1.src.tar.xz
        mv cfe-4.0.1.src clang
    fi

    # rv
    cd "${CUR}"
    cd llvm/tools
    clone_or_update cdl-saarland rv ${BRANCH_RV}
    cd "${CUR}"

    # apply LLVM 4.0 patch
    patch llvm/lib/Transforms/InstCombine/InstCombineSelect.cpp < patch_llvm40.txt

    # build llvm
    cd llvm_build
    cmake ../llvm ${CMAKE_MAKE} -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/llvm_install" \
        -DLLVM_ENABLE_RTTI:BOOL=ON -DLLVM_INCLUDE_TESTS:BOOL=OFF -DLLVM_TARGETS_TO_BUILD="${LLVM_TARGETS}"
    ${MAKE} install
    cd "${CUR}"

    LLVM_VARS=-DLLVM_DIR:PATH="${CUR}/llvm_install/lib/cmake/llvm"
else
    LLVM_VARS=-DCMAKE_DISABLE_FIND_PACKAGE_LLVM=TRUE
fi

if [ ! -e "${CUR}/half" ]; then
    svn checkout svn://svn.code.sf.net/p/half/code/trunk half
fi

# source this file to put clang and impala in path
cat > "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/llvm_install/bin:${CUR}/impala/build/bin:\$PATH"
_EOF_

source "${CUR}/project.sh"

# runtime
cd "${CUR}"
clone_or_update AnyDSL runtime ${BRANCH_RUNTIME}
cd "${CUR}/runtime/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE}
${MAKE}

# thorin
cd "${CUR}"
clone_or_update AnyDSL thorin ${BRANCH_THORIN}
cd "${CUR}/thorin/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${LLVM_VARS} -DHalf_DIR:PATH="${CUR}/half/include"
${MAKE}

# impala
cd "${CUR}"
clone_or_update AnyDSL impala ${BRANCH_IMPALA}
cd "${CUR}/impala/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DThorin_DIR:PATH="${CUR}/thorin/build/share/thorin/cmake"
${MAKE}

# configure stincilla but don't build yet
cd "${CUR}"
clone_or_update AnyDSL stincilla ${BRANCH_STINCILLA}
cd "${CUR}/stincilla/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL-runtime_DIR:PATH="${CUR}/runtime" -DBACKEND:STRING="cpu"
#${MAKE}

cd "${CUR}"

echo
echo "!!! Use the following command in order to have 'impala' and 'clang' in your path:"
echo "!!! source project.sh"
