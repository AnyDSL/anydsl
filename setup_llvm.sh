#!/bin/sh
export CUR=`pwd`
wget http://llvm.org/releases/3.4.2/llvm-3.4.2.src.tar.gz
tar xf llvm-3.4.2.src.tar.gz
rm llvm-3.4.2.src.tar.gz
mv llvm-3.4.2.src llvm
cd llvm/tools
wget http://llvm.org/releases/3.4.2/cfe-3.4.2.src.tar.gz
tar xf cfe-3.4.2.src.tar.gz
rm cfe-3.4.2.src.tar.gz
mv cfe-3.4.2.src clang
cd ${CUR}
mkdir llvm_build
mkdir llvm_install
cd llvm_build
cmake ../llvm -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=${CUR}/llvm_install
make install -j`cat /proc/cpuinfo \\| grep processor \\| echo \`wc -l\` + 1 \\| bc`
cd ${CUR}
