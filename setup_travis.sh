#!/bin/bash
set -eu

if [ ! -e config.sh ]
then
    echo "first configure your build:"
    echo "cp config.sh.template config.sh"
    echo "edit config.sh"
    exit -1
fi

source config.sh

CUR=`pwd`

# fetch sources
git clone https://github.com/AnyDSL/thorin.git -b ${BRANCH}
git clone https://github.com/AnyDSL/impala.git -b ${BRANCH}
git clone https://github.com/simoll/libwfv.git
git clone --recursive https://github.com/AnyDSL/stincilla.git

# create build/install dirs
mkdir -p thorin/build/
mkdir -p impala/build/
mkdir -p libwfv/build/
mkdir -p stincilla/build/

# build llvm
wget http://llvm.org/releases/3.6.2/clang+llvm-3.6.2-x86_64-linux-gnu-ubuntu-14.04.tar.xz
tar -xvf clang+llvm-3.6.2-x86_64-linux-gnu-ubuntu-14.04.tar.xz
rm clang+llvm-3.6.2-x86_64-linux-gnu-ubuntu-14.04.tar.xz
mv clang+llvm-3.6.2-x86_64-linux-gnu-ubuntu-14.04/ llvm_install/

find /home/travis/work/anydsl/llvm_install/share/llvm/cmake/ -type f -exec sed -i 's#/home/development/llvm/3.6.2/final/Phase3/Release/llvmCore-3.6.2-final.install/#/home/travis/work/anydsl/llvm_install/#g' {} \;

#mkdir -p /home/development/llvm/3.6.2/final/Phase3/Release/llvmCore-3.6.2-final.install/
#cp -R llvm_install/ /home/development/llvm/3.6.2/final/Phase3/Release/llvmCore-3.6.2-final.install/

# build libwfv
#cd "${CUR}/libwfv/build"
#cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"
#make -j${THREADS}

# build thorin
cd "${CUR}/thorin/build"
CXX=${CUR}/llvm_install/bin/clang++ cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"
make -j${THREADS}

# build impala
cd "${CUR}/impala/build"
CXX=${CUR}/llvm_install/bin/clang++ cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" -DTHORIN_DIR:PATH="${CUR}/thorin"
make -j${THREADS}

# configure stincilla but don't build yet
cd "${CUR}/stincilla/build"
CXX=${CUR}/llvm_install/bin/clang++ cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" -DTHORIN_DIR:PATH="${CUR}/thorin" -DBACKEND:STRING="cpu"
#make -j${THREADS}
