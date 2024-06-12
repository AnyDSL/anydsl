FORCE=0
VERSION="16.0.4"

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=1
            shift
            ;;
        --version)
            VERSION="$2"
            shift
            shift
            ;;
    esac
done

if [ -d llvm_install && "${FORCE}" != "1" ]; then
    echo "Warning: This will override your llvm_install folder."
    echo "Stopping at this point."
    echo "Run with --foce if you know what you are doing."
else
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/clang+llvm-${VERSION}-x86_64-linux-gnu-ubuntu-22.04.tar.xz
    tar -xf clang+llvm-${VERSION}-x86_64-linux-gnu-ubuntu-22.04.tar.xz
    mv clang+llvm-${VERSION}-x86_64-linux-gnu-ubuntu-22.04 llvm_install
fi
