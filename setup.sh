#!/bin/bash
set -eu

echo ">>> update meta project"
meta_out=$(git pull)
if [ "$meta_out" != "Already up-to-date." ]; then
    echo "meta project has been updated; please rerun script"
    exit 0
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
    cd "${CUR}"
    if [ ! -e "$2" ]; then
        echo ">>> clone $1/$2"
        git clone --recursive `remote $1/$2.git`
        mkdir -p "$2"/build/
    else
        echo ">>> pull $1/$2"
        cd $2
        git pull
        cd ..
    fi
}

# fetch sources
if [ "${LLVM-}" == true ] ; then
    mkdir -p llvm_build/
    
    if [ ! -e  "${CUR}/llvm" ]; then
        wget http://llvm.org/releases/3.8.1/llvm-3.8.1.src.tar.xz
        tar xf llvm-3.8.1.src.tar.xz
        rm llvm-3.8.1.src.tar.xz
        mv llvm-3.8.1.src llvm
        cd llvm/tools
        wget http://llvm.org/releases/3.8.1/cfe-3.8.1.src.tar.xz
        tar xf cfe-3.8.1.src.tar.xz
        rm cfe-3.8.1.src.tar.xz
        mv cfe-3.8.1.src clang
        cd "${CUR}"
    fi
    
    # build llvm
    if [ ! -e "${CUR}/llvm_install/share/llvm/cmake" ]; then
        cd llvm_build
        cmake ../llvm ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/llvm_install" \
            -DLLVM_ENABLE_RTTI:BOOL=ON -DLLVM_INCLUDE_TESTS:BOOL=OFF -DLLVM_TARGETS_TO_BUILD="AArch64;AMDGPU;ARM;NVPTX;X86"
        ${MAKE} install
        cd "${CUR}"
    fi
fi

if [ ! -e "${CUR}/half" ]; then
    svn checkout svn://svn.code.sf.net/p/half/code/trunk half
fi

# rv
if [ "${LLVM-}" == true ] ; then
    clone_or_update cdl-saarland rv
    cd "${CUR}/rv/build"
    cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"
    ${MAKE}
fi

if [ "${LLVM-}" == true ] ; then
    COMMON_CMAKE_VARS=${CMAKE_MAKE}\ -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE}\ -DHalf_DIR:PATH="${CUR}/half/include"\ -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"\ -DRV_DIR:PATH="${CUR}/rv"
else
    COMMON_CMAKE_VARS=${CMAKE_MAKE}\ -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE}\ -DHalf_DIR:PATH="${CUR}/half/include"\ -DCMAKE_DISABLE_FIND_PACKAGE_LLVM=TRUE\ -DCMAKE_DISABLE_FIND_PACKAGE_RV=TRUE
fi

# runtime
clone_or_update AnyDSL runtime
cd "${CUR}/runtime/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE}
${MAKE}

# thorin
clone_or_update AnyDSL thorin
cd "${CUR}/thorin/build"
cmake .. ${COMMON_CMAKE_VARS}
${MAKE}

# impala
clone_or_update AnyDSL impala
cd "${CUR}/impala/build"
cmake .. ${COMMON_CMAKE_VARS} -DTHORIN_DIR:PATH="${CUR}/thorin"
${MAKE}

# source this file to put clang and impala in path
cat > "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/llvm_install/bin:${CUR}/impala/build/bin:\$PATH"
_EOF_

source "${CUR}/project.sh"

# configure stincilla but don't build yet
clone_or_update AnyDSL stincilla
cd "${CUR}/stincilla/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL-runtime_DIR:PATH="${CUR}/runtime" -DBACKEND:STRING="cpu"
#${MAKE}

cd "${CUR}"

echo
echo "!!! Use the following command in order to have 'impala' and 'clang' in your path:"
echo "!!! source project.sh"
