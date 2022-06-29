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

# fetch sources
if [ "${LLVM-}" == true ]; then
    mkdir -p llvm_build/

    if [ "${LLVM_GIT-}" = true ]; then
        clone_or_update ${LLVM_GIT_REPO} llvm-project ${LLVM_GIT_BRANCH}
    else
        if [ ! -e  "${CUR}/llvm-project" ]; then
            wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_SRC_VERSION}/llvm-project-${LLVM_SRC_VERSION}.src.tar.xz
            tar xf llvm-project-${LLVM_SRC_VERSION}.src.tar.xz
            rm llvm-project-${LLVM_SRC_VERSION}.src.tar.xz
            mv llvm-project-${LLVM_SRC_VERSION}.src llvm-project
        fi
    fi
    cd llvm-project
    if ! patch --dry-run --reverse --force -s -p1 -i ../patches/llvm/amdgpu_icmp_fold.patch; then
        patch -p1 -i ../patches/llvm/amdgpu_icmp_fold.patch
        patch -p1 -i ../patches/llvm/nvptx_feature.patch
    fi

    # rv
    if [ "${RV-}" == true ]; then
        cd "${CUR}"
        cd llvm-project
        clone_or_update cdl-saarland rv ${BRANCH_RV}
        cd rv
        git submodule update --init
    fi

    # build llvm
    cd "${CUR}"
    cd llvm_build
    DEFAULT_SYSROOT=
    if [[ ${OSTYPE} == "darwin"* ]]; then
        DEFAULT_SYSROOT=`xcrun --sdk macosx --show-sdk-path`
    fi
    cmake ../llvm-project/llvm ${CMAKE_MAKE} -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON -DLLVM_LINK_LLVM_DYLIB:BOOL=ON -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/llvm_install" \
        -DLLVM_EXTERNAL_PROJECTS="rv" -DLLVM_EXTERNAL_RV_SOURCE_DIR=${CUR}/llvm-project/rv \
        -DLLVM_ENABLE_RTTI:BOOL=ON -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_ENABLE_BINDINGS:BOOL=OFF -DLLVM_INCLUDE_TESTS:BOOL=ON -DLLVM_TARGETS_TO_BUILD:STRING="${LLVM_TARGETS}" -DDEFAULT_SYSROOT:PATH="${DEFAULT_SYSROOT}"
    ${MAKE} install
    cd "${CUR}"

    LLVM_VARS=-DLLVM_DIR:PATH="${CUR}/llvm_install/lib/cmake/llvm"
else
    LLVM_VARS=-DCMAKE_DISABLE_FIND_PACKAGE_LLVM=TRUE
fi

if [ ! -e "${CUR}/half" ]; then
    svn checkout svn://svn.code.sf.net/p/half/code/trunk half
fi

# source this file to put artic, impala, and clang in path
cat > "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/llvm_install/bin:${CUR}/artic/build/bin:${CUR}/impala/build/bin:\${PATH:-}"
export LD_LIBRARY_PATH="${CUR}/llvm_install/lib:\${LD_LIBRARY_PATH:-}"
_EOF_
if [ "${CMAKE-}" == true ]; then
    echo "export PATH=\"${CUR}/cmake_install/bin:\${PATH:-}\"" >> ${CUR}/project.sh
fi

source "${CUR}/project.sh"

# thorin
cd "${CUR}"
clone_or_update AnyDSL thorin ${BRANCH_THORIN}
cd "${CUR}/thorin/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${LLVM_VARS} -DTHORIN_PROFILE:BOOL=${THORIN_PROFILE} -DHalf_DIR:PATH="${CUR}/half/include"
${MAKE}

# artic
cd "${CUR}"
clone_or_update AnyDSL artic ${BRANCH_ARTIC}
cd "${CUR}/artic/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DThorin_DIR:PATH="${CUR}/thorin/build/share/anydsl/cmake"
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
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DRUNTIME_JIT:BOOL=${RUNTIME_JIT} -DDEBUG_OUTPUT:BOOL=${RUNTIME_DEBUG_OUTPUT} -DArtic_DIR:PATH="${CUR}/artic/build/share/anydsl/cmake" -DImpala_DIR:PATH="${CUR}/impala/build/share/anydsl/cmake"
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
echo "!!! Use the following command in order to have 'artic', 'impala', and 'clang' in your path:"
echo "!!! source project.sh"
