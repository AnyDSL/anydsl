#!/usr/bin/env bash
set -eu

COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo ">>> update setup project"
git fetch origin

source config.sh

CUR=`pwd`

function remote {
    if $HTTPS; then
        echo "https://github.com/$1"
    else
        echo "git@github.com:$1"
    fi
}

function make_and_cd {
  mkdir -p $1
  cd $1
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


# Bootstrap the 'project.sh' file.
# source this file to put clang and impala in path
cat > "${CUR}/project.sh" <<_EOF_
export PATH="${CUR}/impala/build/bin:\${PATH:-}"
export LD_LIBRARY_PATH="${CUR}/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${CUR}/lib:\${LIBRARY_PATH:-}"
_EOF_

# Fetch & build the LLVM for SX-Aurora stack from scratch.
if [ "${LLVM-}" == true ] ; then
    if [ ! -e  "${CUR}/src/llvm-project" ]; then
        echo "> The variable LLVM=true and llvm sources not found."
        echo "> Will clone and build LLVM for SX-Aurora now.."
	echo "> (sleep 5s - abort this script and set LLVM=false to use LLVM from your PATH instead.)"
	sleep 5s

	# Fetch and build.
	SXURL=${SXURL:-https://github.com/sx-aurora-dev}
	git clone ${SXURL}/llvm-dev.git -b hpce/develop
	REPOS=${SXURL} BRANCH=hpce/develop BUILD_TYPE=Release make -f ./llvm-dev/Makefile clone
	REPOS=${SXURL} BRANCH=hpce/develop BUILD_TYPE=Release make -f ./llvm-dev/Makefile install

	# Configure project.sh to active the LLVM stack with everyting else.
	echo "source llvm-dev/enter.sh" >> project.sh
    fi
fi

# If llvm-config not found use the llvm-dev/enter.sh script to active LLVM for SX-Aurora.
if ! [ $(type -P "llvm-config") ]; then
  if [ -e "${CUR}/llvm-dev" ]; then
    echo "> Found LLVM for SX-Aurora llvm-dev/ and sourcing it."
    source ${CUR}/llvm-dev/enter.sh
  fi
else
  echo "> Found llvm-config in PATH!"
fi

# Some llvm-config has to be in our path now.
if [ $(type -P "llvm-config") ]; then
  LLVM_PREFIX=$(dirname $(dirname `which llvm-config`))
  LLVM_VARS=-DLLVM_DIR:PATH="${LLVM_PREFIX}/lib/cmake/llvm/"
  LLVM=true
  echo "> Using LLVM installed at ${LLVM_PREFIX}"
else
  echo "ERROR: llvm-config was not found in your PATH, neither was there a script to enter the LLVM for SX-Aurora prefix (${CUR}/llvm-dev/enter.sh missing). Run this script with LLVM=true to fetch and build the LLVM for SX-Aurora stack or make llvm-config for SX-Aurora available in your path."
  exit
fi

if [ "${CMAKE-}" == true ] ; then
    echo "export PATH=\"${CUR}/cmake_install/bin:\${PATH:-}\"" >> ${CUR}/project.sh
fi

echo "sourcing ${CUR}/project.sh"

source "${CUR}/project.sh"

cache_vh=${CUR}/presets/vh.cmake
cache_ve=${CUR}/presets/ve.cmake

# thorin
cd "${CUR}"
clone_or_update AnyDSL thorin ${BRANCH_THORIN}
make_and_cd "${CUR}/thorin/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${LLVM_VARS} -DTHORIN_PROFILE:BOOL=${THORIN_PROFILE} -DHalf_DIR:PATH="${CUR}/half/include" -C ${cache_vh}
${MAKE}

# impala
cd "${CUR}"
clone_or_update AnyDSL impala ${BRANCH_IMPALA}
make_and_cd "${CUR}/impala/build"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DThorin_DIR:PATH="${CUR}/thorin/build/share/anydsl/cmake" -C ${cache_vh}
${MAKE}

# runtime
cd "${CUR}"
clone_or_update AnyDSL runtime ${BRANCH_RUNTIME}

# Runtime for VH
make_and_cd "${CUR}/runtime/build_vh"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DRUNTIME_JIT:BOOL=On -DImpala_DIR:PATH="${CUR}/impala/build/share/anydsl/cmake" -C  ${cache_vh}
${MAKE}

# (Minimal) runtime for VE
make_and_cd "${CUR}/runtime/build_ve"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DRUNTIME_JIT:BOOL=Off -DImpala_DIR:PATH="${CUR}/impala/build/share/anydsl/cmake" -C ${cache_ve}
${MAKE}

AnyDSL_rt_ve=${CUR}/runtime/build_ve/share/anydsl/cmake
AnyDSL_rt_vh=${CUR}/runtime/build_vh/share/anydsl/cmake

# configure stincilla but don't build yet
cd "${CUR}"
clone_or_update AnyDSL stincilla ${BRANCH_STINCILLA}
make_and_cd "${CUR}/stincilla/build_vh"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${AnyDSL_rt_vh}" -DBACKEND:STRING="avx" -C ${cache_vh}

make_and_cd "${CUR}/stincilla/build_ve"
cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${AnyDSL_rt_ve}" -DBACKEND:STRING="ve" -C ${cache_ve}
#${MAKE}

# configure rodent but don't build yet # TODO
if [ "$CLONE_RODENT" = true ]; then
    cd "${CUR}"
    clone_or_update AnyDSL rodent ${BRANCH_RODENT}
    cd "${CUR}/rodent/build"
    cmake .. ${CMAKE_MAKE} -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -DAnyDSL_runtime_DIR:PATH="${AnyDSL_rt_vh}" -C ${cache_vh}
    #${MAKE}
fi

cd "${CUR}"

echo
echo "!!! Use the following command in order to have 'impala' and 'clang' in your path:"
echo "!!! source project.sh"
