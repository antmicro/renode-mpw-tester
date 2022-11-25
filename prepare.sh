#!/bin/bash

set -e

BASE_DIR=${GITHUB_WORKSPACE:-$(pwd)}

TEST_NAME=${TEST_NAME:-aes_test}
DESIGN_NAME=${DESIGN_NAME:-aes}

TOOLCHAIN_DIRECTORY="riscv32-unknown-elf-gcc"

download_toolchain()
{
    URL="https://dl.antmicro.com/projects/renode/toolchains/riscv-unknown-elf-gcc-softconsole-6.1.tar.gz"
    ARCHIVE="riscv-unknown-elf-gcc.tar.gz"

    if ! [ -e "$ARCHIVE" ]
    then
        curl "$URL" -o "$ARCHIVE"
        tar -xzf "$ARCHIVE"
        rm "$ARCHIVE"
    fi
}

build_toolchain()
{
    [ -d "$BASE_DIR/$TOOLCHAIN_DIRECTORY" ] \
    || mkdir "$BASE_DIR/$TOOLCHAIN_DIRECTORY"

    [ -d "$BASE_DIR/"riscv-gnu-toolchain ] \
    || git clone https://github.com/riscv-collab/riscv-gnu-toolchain

    cd riscv-gnu-toolchain

    git submodule update --init --recursive

    mkdir -p build

    pushd build >/dev/null

    ../configure --with-arch=rv32i --prefix="$BASE_DIR/$TOOLCHAIN_DIRECTORY"
    make -j$(nproc)

    popd >/dev/null
}

prepare_repository()
{
    # We can't detect if our patches were applied, so we assume that they were unless artifacts directory is nonexistent
    [ -d "$BASE_DIR/artifacts" ] \
    && return

    git submodule update --init

    pushd "$BASE_DIR"/design >/dev/null

    make install install_mcw
    git apply $BASE_DIR/patches/Makefile.patch

    pushd mgmt_core_wrapper/litex >/dev/null
    git apply $BASE_DIR/patches/caravel.py.patch
    popd >/dev/null

    popd >/dev/null
}

prepare_tests()
{
    # We can't detect if our patches were applied, so we assume that they were unless artifacts directory is nonexistent
    [ -d "$BASE_DIR/artifacts" ] \
    && return

    pushd "$BASE_DIR"/design 2>/dev/null

    [ -f "$BASE_DIR"/patches/design.patch ] \
    && git apply "$BASE_DIR"/patches/design.patch

    popd >/dev/null
}

prepare_artifacts()
{
    mkdir -p "$BASE_DIR"/artifacts
}

case "${1:-ALL}" in
    toolchain) download_toolchain ;;
    toolchain_download) download_toolchain ;;
    toolchain_git) build_toolchain ;;
    repository) prepare_repository ;;
    tests) prepare_tests ;;
    artifacts) prepare_artifacts ;;
    ALL)
        download_toolchain
        prepare_repository
        prepare_tests
        prepare_artifacts
    ;;
esac
