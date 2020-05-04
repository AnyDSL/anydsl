#!/usr/bin/env bash
set -eu

COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo ">>> update setup project"
git fetch origin

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "your branch is up-to-date"
elif [ $LOCAL = $BASE ]; then
    echo "your branch is behind your tracking branch"
    echo "I pull and rerun the script "
    git pull
    ./$0
    exit $?
elif [ $REMOTE = $BASE ]; then
    echo "your branch is ahead of your tracking branch"
    echo "remember to push your changes but I will run the script anyway"
else
    echo "your branch and your tracking remote branch have diverged"
    echo "resolve all conflicts before rerunning the script"
    exit 1
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
        git fetch --tags origin
        git checkout $branch
        set +e
        git symbolic-ref HEAD
        if [ $? -eq 0 ]; then
            git pull
        fi
        set -e
        cd ..
    fi
    mkdir -p "$2"/build/
}

# build custom CMake
if [ "${CMAKE-}" == true ] ; then
    mkdir -p cmake_build

    clone_or_update Kitware CMake ${BRANCH_CMAKE}

    cd cmake_build
    cmake ../CMake -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/cmake_install"
    ${MAKE} install
    cd "${CUR}"

    export PATH="${CUR}/cmake_install/bin:${PATH}"
    echo $PATH
fi

# fetch sources
if [ "${LLVM-}" == true ] ; then
    mkdir -p llvm_build/

    if [ ! -e  "${CUR}/llvm" ]; then
        LLVM_VERSION=8.0.1
        wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz
        tar xf llvm-${LLVM_VERSION}.src.tar.xz
        rm llvm-${LLVM_VERSION}.src.tar.xz
        mv llvm-${LLVM_VERSION}.src llvm
        patch llvm/include/llvm/Demangle/MicrosoftDemangleNodes.h < gcc-10.patch
        cd llvm
        patch -p1 -i ../nvptx_feature_ptx60.patch
        cd tools
        wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/cfe-${LLVM_VERSION}.src.tar.xz
        wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/lld-${LLVM_VERSION}.src.tar.xz
        tar xf cfe-${LLVM_VERSION}.src.tar.xz
        tar xf lld-${LLVM_VERSION}.src.tar.xz
        rm cfe-${LLVM_VERSION}.src.tar.xz
        rm lld-${LLVM_VERSION}.src.tar.xz
        mv cfe-${LLVM_VERSION}.src clang
        mv lld-${LLVM_VERSION}.src lld
    fi

    # rv
    cd "${CUR}"
    cd llvm/tools
    clone_or_update cdl-saarland rv ${BRANCH_RV}
    cd rv
    git submodule update --init
    cd "${CUR}"

    # build llvm
    cd llvm_build
    DEFAULT_SYSROOT=
    if [[ ${OSTYPE} == "darwin"* ]] ; then
        DEFAULT_SYSROOT=`xcrun --sdk macosx --show-sdk-path`
    fi
    cmake ../llvm ${CMAKE_MAKE} -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON -DLLVM_LINK_LLVM_DYLIB:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/llvm_install" \
        -DLLVM_ENABLE_RTTI:BOOL=ON -DLLVM_ENABLE_CXX1Y:BOOL=ON -DLLVM_INCLUDE_TESTS:BOOL=ON -DLLVM_TARGETS_TO_BUILD:STRING="${LLVM_TARGETS}" -DDEFAULT_SYSROOT:PATH="${DEFAULT_SYSROOT}"
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
export PATH="${CUR}/llvm_install/bin:${CUR}/impala/build/bin:\${PATH:-}"
export LD_LIBRARY_PATH="${CUR}/llvm_install/lib:\${LD_LIBRARY_PATH:-}"
_EOF_
if [ "${CMAKE-}" == true ] ; then
    echo "export PATH=\"${CUR}/cmake_install/bin:\${PATH:-}\"" >> ${CUR}/project.sh
fi

source "${CUR}/project.sh"

# thorin
cd "${CUR}"
clone_or_update AnyDSL thorin ${BRANCH_THORIN}
cd "${CUR}/thorin/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${LLVM_VARS} -DTHORIN_PROFILE:BOOL=${THORIN_PROFILE} -DHalf_DIR:PATH="${CUR}/half/include"
${MAKE}

# impala
cd "${CUR}"
clone_or_update AnyDSL impala ${BRANCH_IMPALA}
cd "${CUR}/impala/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DThorin_DIR:PATH="${CUR}/thorin/build/share/anydsl/cmake"
${MAKE}

# runtime
cd "${CUR}"
clone_or_update AnyDSL runtime ${BRANCH_RUNTIME}
cd "${CUR}/runtime/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DRUNTIME_JIT:BOOL=${RUNTIME_JIT} -DImpala_DIR:PATH="${CUR}/impala/build/share/anydsl/cmake"
${MAKE}

# configure stincilla but don't build yet
cd "${CUR}"
clone_or_update AnyDSL stincilla ${BRANCH_STINCILLA}
cd "${CUR}/stincilla/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${CUR}/runtime/build/share/anydsl/cmake" -DBACKEND:STRING="cpu"
#${MAKE}

# configure rodent but don't build yet
if [ "$CLONE_RODENT" = true ]; then
    cd "${CUR}"
    clone_or_update AnyDSL rodent ${BRANCH_RODENT}
    cd "${CUR}/rodent/build"
    cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${CUR}/runtime/build/share/anydsl/cmake"
    #${MAKE}
fi

cd "${CUR}"

echo
echo "!!! Use the following command in order to have 'impala' and 'clang' in your path:"
echo "!!! source project.sh"
