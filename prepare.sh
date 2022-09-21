#!/bin/sh

set -e

TEST_NAME=${TEST_NAME:-aes_test}
DESIGN_NAME=${DESIGN_NAME:-aes}
GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}

prepare_the_repository()
{
    # We can't detect is our patches were applied, so we assume that they were unless artifacts directory is nonexistent
    [ -d "$GITHUB_WORKSPACE/artifacts" ] \
    && return

    git submodule update --init

    cd "$GITHUB_WORKSPACE"/design
    make install install_mcw
    git apply $GITHUB_WORKSPACE/patches/Makefile.patch

    cd "$GITHUB_WORKSPACE"/design/mgmt_core_wrapper/litex
    git apply $GITHUB_WORKSPACE/patches/caravel.py.patch
    cd "$GITHUB_WORKSPACE"
}

prepare_tests()
{
    # We can't detect is our patches were applied, so we assume that they were unless artifacts directory is nonexistent
    [ -d "$GITHUB_WORKSPACE/artifacts" ] \
    && return

    cd "$GITHUB_WORKSPACE"/design
    [ -f "$GITHUB_WORKSPACE"/patches/design.patch ] \
    && git apply "$GITHUB_WORKSPACE"/patches/design.patch
    cd "$GITHUB_WORKSPACE"
}

prepare_artifacts()
{
    mkdir -p "$GITHUB_WORKSPACE"/artifacts
}

prepare_the_repository
prepare_tests
prepare_artifacts
