echo "Setting up project from folder ${PWD}"

export THORIN_PLATFORM_PATH="${PWD}/runtime/platforms"

export PATH="${PWD}/build/bin:${PATH:-}"
export LD_LIBRARY_PATH="${PWD}/build/lib:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${PWD}/build/lib:${LIBRARY_PATH:-}"
export CMAKE_PREFIX_PATH="${PWD}/build/share/anydsl/cmake:${CMAKE_PREFIX_PATH:-}"

if [ -d ${PWD}/llvm_install ]; then
    echo "Detected llvm_install directory, adding llvm to path"
    export PATH="${PWD}/llvm_install/bin:${PATH:-}"
    export LD_LIBRARY_PATH="${PWD}/llvm_install/lib:${LD_LIBRARY_PATH:-}"
    export LIBRARY_PATH="${PWD}/llvm_install/lib:${LIBRARY_PATH:-}"
    export CMAKE_PREFIX_PATH="${PWD}/llvm_install/lib/cmake/llvm:${CMAKE_PREFIX_PATH:-}"
fi

if [ "${ZSH_VERSION:-}" != "" ]; then
    echo "Detected zsh, setting up completion scripts"
    export fpath=(${PWD}/zsh ${fpath:-})
    compinit
fi

echo "Setting up rebuild alias"
alias anydsl-rebuild="cmake --build ${PWD}/build"
alias anydsl-config="ccmake ${PWD}/build"
