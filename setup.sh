#!/bin/bash
set -eu

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

# fetch sources
if [ "${TRAVIS-}" == true ] ; then
    wget http://llvm.org/releases/3.8.1/clang+llvm-3.8.1-x86_64-linux-gnu-ubuntu-14.04.tar.xz
    tar -xvf clang+llvm-3.8.1-x86_64-linux-gnu-ubuntu-14.04.tar.xz
    rm clang+llvm-3.8.1-x86_64-linux-gnu-ubuntu-14.04.tar.xz
    mv clang+llvm-3.8.1-x86_64-linux-gnu-ubuntu-14.04/ llvm_install/
else
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
    fi
fi

cd "${CUR}"

if [ ! -e "${CUR}/half" ]; then
    svn checkout svn://svn.code.sf.net/p/half/code/trunk half
fi
if [ ! -e "${CUR}/thorin" ]; then
    git clone `remote AnyDSL/thorin.git`
fi
if [ ! -e "${CUR}/impala" ]; then
    git clone `remote AnyDSL/impala.git`
fi
if [ ! -e "${CUR}/rv" ]; then
    git clone `remote simoll/rv.git`
fi
if [ ! -e "${CUR}/stincilla" ]; then
    git clone --recursive `remote AnyDSL/stincilla.git`
fi

# create build/install dirs
mkdir -p thorin/build/
mkdir -p impala/build/
mkdir -p rv/build/
mkdir -p stincilla/build/

# build rv
cd "${CUR}/rv/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"
${MAKE}

COMMON_CMAKE_VARS=${CMAKE_MAKE}\ -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE}\ -DHalf_DIR:PATH="${CUR}/half/include"\ -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"\ -DRV_DIR:PATH="${CUR}/rv"

# build thorin
cd "${CUR}/thorin/build"
cmake .. ${COMMON_CMAKE_VARS}
${MAKE}

# build impala
cd "${CUR}/impala/build"
cmake .. ${COMMON_CMAKE_VARS} -DTHORIN_DIR:PATH="${CUR}/thorin"
${MAKE}

cd "${CUR}"

# source this file to put clang and impala in your path
cat > "project.sh" <<_EOF_
export PATH="${CUR}/llvm_install/bin:${CUR}/impala/build/bin:\$PATH"
_EOF_

source project.sh

# configure stincilla but don't build yet
cd "${CUR}/stincilla/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" -DTHORIN_DIR:PATH="${CUR}/thorin" -DBACKEND:STRING="cpu"
#${MAKE}

echo
echo "Use the following command in order to have 'impala' and 'clang' in your path:"
echo "source project.sh"
echo "This has already been done for this shell session"
echo "WARNING: Note that this will override any system installation of llvm/clang in your current shell session."
