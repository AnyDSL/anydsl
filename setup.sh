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
wget http://llvm.org/releases/3.4.2/llvm-3.4.2.src.tar.gz
tar xf llvm-3.4.2.src.tar.gz
rm llvm-3.4.2.src.tar.gz
mv llvm-3.4.2.src llvm
cd llvm/tools
wget http://llvm.org/releases/3.4.2/cfe-3.4.2.src.tar.gz
tar xf cfe-3.4.2.src.tar.gz
rm cfe-3.4.2.src.tar.gz
mv cfe-3.4.2.src clang
cd "${CUR}"
git clone git@github.com:AnyDSL/thorin.git -b ${BRANCH}
git clone git@github.com:AnyDSL/impala.git -b ${BRANCH}
git clone git@github.com:AnyDSL/anydsl.github.io
git clone https://github.com/AnyDSL/anydsl.wiki.git

# create build/install dirs
mkdir -p llvm_build
mkdir -p llvm_install
mkdir -p thorin/build
mkdir -p impala/build

# build llvm
cd llvm_build
cmake ../llvm -DLLVM_REQUIRES_RTTI:BOOL=true -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/llvm_install"
make install -j${THREADS}

# build thorin
cd "${CUR}/thorin/build"
cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" -DBUILD_STATIC=OFF
make -j${THREADS}

# build impala
cd "${CUR}/impala/build"
cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" -DTHORIN_DIR:PATH="${CUR}/thorin"
make -j${THREADS}
export PATH="${CUR}/llvm_install/bin:${CUR}/impala/build/bin:$PATH"

# symlink git hooks
ln -s "${CUR}/scripts/pre-push-impala.hook" "${CUR}/impala/.git/hooks/pre-push"
ln -s "${CUR}/scripts/pre-push-thorin.hook" "${CUR}/thorin/.git/hooks/pre-push"
ln -s "${CUR}/scripts/pre-commit-wiki.hook" "${CUR}/anydsl.wiki/.git/hooks/pre-push"

# go back to current dir
cd "${CUR}"

echo
echo "Put the following line into your '~/.bashrc' in order to have 'impala' and 'clang' in your path:"
echo "export PATH=${CUR}/llvm_install/bin:${CUR}/impala/build/bin:\$PATH"
echo "WARNING: Note that this will override any system installation of llvm/clang."
