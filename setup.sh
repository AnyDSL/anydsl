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
    echo "push your changes and rerun the script "
    exit 1
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

# fetch sources
if [ "${LLVM-}" == true ] ; then
    mkdir -p llvm_build/

    if [ ! -e  "${CUR}/llvm" ]; then
        wget http://releases.llvm.org/5.0.1/llvm-5.0.1.src.tar.xz
        tar xf llvm-5.0.1.src.tar.xz
        rm llvm-5.0.1.src.tar.xz
        mv llvm-5.0.1.src llvm
        cd llvm
        patch -p1 -i ../gcc8-llvm.patch
        cd tools
        wget http://releases.llvm.org/5.0.1/cfe-5.0.1.src.tar.xz
        tar xf cfe-5.0.1.src.tar.xz
        rm cfe-5.0.1.src.tar.xz
        mv cfe-5.0.1.src clang
    fi

    # rv
    cd "${CUR}"
    cd llvm/tools
    clone_or_update cdl-saarland rv ${BRANCH_RV}
    cd "${CUR}"

    # build llvm
    cd llvm_build
    cmake ../llvm ${CMAKE_MAKE} -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX:PATH="${CUR}/llvm_install" \
        -DLLVM_ENABLE_RTTI:BOOL=ON -DLLVM_INCLUDE_TESTS:BOOL=ON -DLLVM_TARGETS_TO_BUILD="${LLVM_TARGETS}"
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

source "${CUR}/project.sh"

# thorin
cd "${CUR}"
clone_or_update AnyDSL thorin ${BRANCH_THORIN}
cd "${CUR}/thorin/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${LLVM_VARS} -DTHORIN_PROFILE=${THORIN_PROFILE} -DHalf_DIR:PATH="${CUR}/half/include"
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
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DRUNTIME_JIT=${RUNTIME_JIT} -DImpala_DIR:PATH="${CUR}/impala/build/share/anydsl/cmake"
${MAKE}

# configure stincilla but don't build yet
cd "${CUR}"
clone_or_update AnyDSL stincilla ${BRANCH_STINCILLA}
cd "${CUR}/stincilla/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${CUR}/runtime/build/share/anydsl/cmake" -DBACKEND:STRING="cpu"
#${MAKE}

# configure traversal but don't build yet
cd "${CUR}"
clone_or_update AnyDSL traversal ${BRANCH_TRAVERSAL}
cd "${CUR}/traversal/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${CUR}/runtime/build/share/anydsl/cmake"
#${MAKE}

cd "${CUR}"

echo
echo "!!! Use the following command in order to have 'impala' and 'clang' in your path:"
echo "!!! source project.sh"
