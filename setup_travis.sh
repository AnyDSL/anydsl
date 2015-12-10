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

#mkdir -p /home/development/llvm/3.6.2/final/Phase3/Release/llvmCore-3.6.2-final.install/
#cp -R llvm_install/ /home/development/llvm/3.6.2/final/Phase3/Release/llvmCore-3.6.2-final.install/

# build libwfv
#cd "${CUR}/libwfv/build"
#cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"
#make -j${THREADS}

# build thorin
cd "${CUR}/thorin/build"
cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} #-DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake"
make -j${THREADS}

# build impala
cd "${CUR}/impala/build"
cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DTHORIN_DIR:PATH="${CUR}/thorin" #-DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" 
make -j${THREADS}

cd "${CUR}"

# source this file to put clang and impala in your path
cat > "project.sh" <<_EOF_
export PATH="${CUR}/llvm_install/bin:${CUR}/impala/build/bin:\$PATH"
_EOF_

source project

# configure stincilla but don't build yet
cd "${CUR}/stincilla/build"
cmake .. -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DLLVM_DIR:PATH="${CUR}/llvm_install/share/llvm/cmake" -DTHORIN_DIR:PATH="${CUR}/thorin" -DBACKEND:STRING="cpu"
#make -j${THREADS}

# symlink git hooks
#ln -s "${CUR}/scripts/pre-push-impala.hook" "${CUR}/impala/.git/hooks/pre-push"
#ln -s "${CUR}/scripts/pre-push-thorin.hook" "${CUR}/thorin/.git/hooks/pre-push"
ln -s "${CUR}/scripts/post-merge" "${CUR}/impala/.git/hooks/."
ln -s "${CUR}/scripts/post-merge" "${CUR}/thorin/.git/hooks/."

echo
echo "Use the following command in order to have 'impala' and 'clang' in your path:"
echo "source project.sh"
echo "This has already been done for this shell session"
echo "WARNING: Note that this will override any system installation of llvm/clang in you current shell session."