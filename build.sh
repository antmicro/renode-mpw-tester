#!/bin/sh

set -e

TEST_NAME=${TEST_NAME:-aes_test}
DESIGN_NAME=${DESIGN_NAME:-aes}
GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}

prepare_the_repository()
{
    mkdir -p "$GITHUB_WORKSPACE"/artifacts
    git submodule update --init
    cd "$GITHUB_WORKSPACE"/design
    make install install_mcw
    git apply "$GITHUB_WORKSPACE"/patches/Makefile.patch
    cd "$GITHUB_WORKSPACE"/design/mgmt_core_wrapper/litex
    git apply "$GITHUB_WORKSPACE"/patches/caravel.py.patch
}

build_soc_configuration()
{
      cd "$GITHUB_WORKSPACE"/design/mgmt_core_wrapper/litex
      make mgmt_soc
      cp csr.json "$GITHUB_WORKSPACE"/artifacts
}

build_renode_configuration()
{
    python3 scripts/litex_json2renode.py --auto-align dff --auto-align sram --repl design.repl "$GITHUB_WORKSPACE"/artifacts/csr.json
    cat design.repl scripts/design-addend.repl > "$GITHUB_WORKSPACE"/artifacts/design.repl
    cp scripts/design.resc "$GITHUB_WORKSPACE"/artifacts
    cp scripts/design.robot "$GITHUB_WORKSPACE"/artifacts
}

build_test()
{
    cd "$GITHUB_WORKSPACE"/design
    [ -f "$GITHUB_WORKSPACE"/patches/design.patch ] && git apply "$GITHUB_WORKSPACE"/patches/design.patch
    make verify-"$TEST_NAME"-elf cp "$GITHUB_WORKSPACE"/design/verilog/dv/"$TEST_NAME"/"$TEST_NAME".elf "$GITHUB_WORKSPACE"/artifacts/test.el
    cp "$GITHUB_WORKSPACE"/design/verilog/dv/"$TEST_NAME"/"$TEST_NAME".elf "$GITHUB_WORKSPACE"/artifacts/test.elf
}

verilate_design()
{
    VERILATOR_DIR=${VERILATOR_DIR:-verilator}
    RENODE_CLONE_DIR=${RENODE_CLONE_DIR:-renode}
    BUILD_DIR=${BUILD_DIR:-build}

    cd "$VERILATOR_DIR"
    cp $GITHUB_WORKSPACE/design/verilog/rtl/$DESIGN_NAME/generated/$DESIGN_NAME.v .
    
    # clone renode
    [ -e "$RENODE_CLONE_DIR" ] \
    && {
        cd "$RENODE_CLONE_DIR"
        git pull --depth=1
        cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"
    } \
    || git clone --depth=1 --branch 37446-mpw_testing https://github.com/renode/renode

    cd "$RENODE_CLONE_DIR"
    git submodule update --init src/Infrastructure
    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"

    [ -e "$BUILD_DIR" ] \
    || mkdir "$BUILD_DIR"

    cd "$BUILD_DIR"
    cmake -DCMAKE_BUILD_TYPE=Release -DUSER_RENODE_DIR="$GITHUB_WORKSPACE/$RENODE_CLONE_DIR"  ..
    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"

    echo 10
    make libVtop
    echo 11
    cp libVtop.so $GITHUB_WORKSPACE/artifacts
}

run_test()
{
    echo run test
    # with:
      # renode-version: '1.13.1+20220918git57f09419'
      # tests-to-run: 'artifacts/*.robot'
      # artifacts-path: $GITHUB_WORKSPACE/artifacts
}

# prepare_the_repository
build_soc_configuration
build_renode_configuration
build_test
verilate_design
# run_test
