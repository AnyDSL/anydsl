#!/usr/bin/env bash
set -eu

COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo ">>> update setup project"
git fetch

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "your branch is up-to-date"
elif [ $LOCAL = $BASE ]; then
    echo "your branch is behind your tracking branch"
    echo "please update your repository"
elif [ $REMOTE = $BASE ]; then
    echo "your branch is ahead of your tracking branch"
    echo "remember to push your changes"
else
    echo "your branch and your tracking remote branch have diverged"
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
if [ "${CMAKE-}" == true ]; then
    mkdir -p cmake_build

    clone_or_update Kitware CMake ${BRANCH_CMAKE}

    cd cmake_build
    cmake ../CMake -DBUILD_CursesDialog:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/cmake_install"
    ${MAKE} install
    cd "${CUR}"

    export PATH="${CUR}/cmake_install/bin:${PATH}"
    echo $PATH
fi

if [ "${LLVM_PREBUILD-}" == true ]; then
    if [ ! -d llvm_install ]; then
        wget https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.4/clang+llvm-16.0.4-x86_64-linux-gnu-ubuntu-22.04.tar.xz
        tar -xf clang+llvm-16.0.4-x86_64-linux-gnu-ubuntu-22.04.tar.xz
        mv clang+llvm-16.0.4-x86_64-linux-gnu-ubuntu-22.04 llvm_install
        cd llvm_install
        cd "${CUR}"
    else
        echo "remember to download LLVM if a newer build is available."
    fi
    LLVM_EXTERN="${CUR}/llvm_install"
    : ${RV_MODULE_BUILD:=ON}
fi
if [ "${LLVM_EXTERN:-}" != "" ] && [ -d ${LLVM_EXTERN:-} ]; then
    LLVM_AUTOBUILD=OFF
elif [ "${LLVM_AUTOBUILD:-}" == "" ]; then
    LLVM_AUTOBUILD=ON
fi

mkdir -p build

# source this file to put artic, impala, and clang in path
cat > "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/build/bin:\${PATH:-}"
export LD_LIBRARY_PATH="${CUR}/build/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${CUR}/build/lib:\${LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${CUR}/build/share/anydsl/cmake:\${CMAKE_PREFIX_PATH:-}"
export THORIN_RUNTIME_PATH="${CUR}/runtime/platforms"
_EOF_

if [ "${LLVM_EXTERN:-}" != "" ] && [ -d ${LLVM_EXTERN:-} ]; then
cat >> "${CUR}/project.sh" <<_EOF_
export PATH="${LLVM_EXTERN}/bin:\${PATH:-}"
export LD_LIBRARY_PATH="${LLVM_EXTERN}/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${LLVM_EXTERN}/lib:\${LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${LLVM_EXTERN}/lib/cmake/llvm:\${CMAKE_PREFIX_PATH:-}"
_EOF_
fi

if [ "${LLVM_AUTOBUILD:-}" == "ON" ] || [ "${LLVM_AUTOBUILD:-}" == "true" ]; then
cat >> "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/build/_deps/llvm-build/bin:\${PATH:-}"
export LD_LIBRARY_PATH="${CUR}/build/_deps/llvm-build/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${CUR}/build/_deps/llvm-build/lib:\${LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${CUR}/build/_deps/llvm-build/lib/cmake/llvm:\${CMAKE_PREFIX_PATH:-}"
_EOF_
fi

if [ "${CMAKE-}" == true ]; then
cat >> "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/cmake_install/bin:\${PATH:-}"
_EOF_
fi

cat >> "${CUR}/project.sh" <<_EOF_
if [ "\${TBBROOT:-}" = "" ] && [ -f /opt/intel/oneapi/setvars.sh ]; then
    source /opt/intel/oneapi/setvars.sh
fi
if [ "\${ZSH_VERSION:-}" != "" ]; then
    export fpath=(${CUR}/zsh \${fpath:-})
    compinit
fi
alias anydsl-rebuild="ninja -C ${CUR}/build"
_EOF_

source "${CUR}/project.sh"

cd "${CUR}/applications"

BUILD_APPLICATIONS=""
if [ "${CLONE_STINCILLA}" == true ]; then
    clone_or_update AnyDSL stincilla ${BRANCH_STINCILLA}
    BUILD_APPLICATIONS="-DAnyDSL_BUILD_stincilla:BOOL=${BUILD_STINCILLA} ${BUILD_APPLICATIONS}"
fi
if [ "${CLONE_RODENT}" == true ]; then
    clone_or_update AnyDSL rodent ${BRANCH_RODENT}
    BUILD_APPLICATIONS="-DAnyDSL_BUILD_rodent:BOOL=${BUILD_RODENT} ${BUILD_APPLICATIONS}"
fi

cd "${CUR}/build"
cmake \
    ${CMAKE_MAKE} \
    -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DRUNTIME_JIT:BOOL=${RUNTIME_JIT} \
    -DBUILD_TESTING:BOOL=OFF \
    -DAnyDSL_PKG_Half_AUTOBUILD:BOOL=ON \
    -DAnyDSL_PKG_LLVM_AUTOBUILD:BOOL=${LLVM_AUTOBUILD} \
    -DAnyDSL_PKG_RV_AUTOBUILD:BOOL=${RV_MODULE_BUILD} \
    -DAnyDSL_thorin_BRANCH:STRING=${BRANCH_THORIN} \
    -DAnyDSL_artic_BRANCH:STRING=${BRANCH_ARTIC} \
    -DAnyDSL_impala_BRANCH:STRING=${BRANCH_IMPALA} \
    -DAnyDSL_runtime_BRANCH:STRING=${BRANCH_RUNTIME} \
    -DAnyDSL_PKG_LLVM_VERSION:STRING=${LLVM_VERSION} \
    -DLLVM_TARGETS_TO_BUILD:STRING=${LLVM_TARGETS} \
    -DLLVM_LINK_LLVM_DYLIB:BOOL=ON \
    -DAnyDSL_PKG_RV_TAG:STRING=${RV_TAG} \
    ${BUILD_APPLICATIONS} \
    ${CUR}
${MAKE}
cd "${CUR}"

echo
echo "!!! Use the following command in order to have 'artic', 'impala', and 'clang' in your path:"
echo "!!! source project.sh"
