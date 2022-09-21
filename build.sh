#!/bin/sh

set -e

TEST_NAME=${TEST_NAME:-aes_test}
DESIGN_NAME=${DESIGN_NAME:-aes}
GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}

build_soc_configuration()
{
      cd "$GITHUB_WORKSPACE"/design/mgmt_core_wrapper/litex
      make mgmt_soc
      cp csr.json "$GITHUB_WORKSPACE"/artifacts
      cd "$GITHUB_WORKSPACE"
}

build_renode_configuration()
{
    python3 "$GITHUB_WORKSPACE"/scripts/litex_json2renode.py --auto-align dff --auto-align sram --repl design.repl "$GITHUB_WORKSPACE"/artifacts/csr.json
    cat design.repl scripts/design-addend.repl > "$GITHUB_WORKSPACE"/artifacts/design.repl
    cp scripts/design.resc "$GITHUB_WORKSPACE"/artifacts
    cp scripts/design.robot "$GITHUB_WORKSPACE"/artifacts
}

build_test()
{
    cd "$GITHUB_WORKSPACE"/design
    make verify-"$TEST_NAME"-elf
    cp "$GITHUB_WORKSPACE"/design/verilog/dv/"$TEST_NAME"/"$TEST_NAME".elf "$GITHUB_WORKSPACE"/artifacts/test.elf
    cd "$GITHUB_WORKSPACE"
}

verilate_design()
{
    VERILATOR_DIR=${VERILATOR_DIR:-verilator}
    RENODE_CLONE_DIR=${RENODE_CLONE_DIR:-renode}
    BUILD_DIR=${BUILD_DIR:-build}

    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"
    cp $GITHUB_WORKSPACE/design/verilog/rtl/$DESIGN_NAME/generated/$DESIGN_NAME.v .
    
    # clone renode
    [ -e "$GITHUB_WORKSPACE/$VERILATOR_DIR/$RENODE_CLONE_DIR" ] \
    && {
        cd "$GITHUB_WORKSPACE/$VERILATOR_DIR/$RENODE_CLONE_DIR"
        git pull --depth=1
        cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"
    } \
    || git clone --depth=1 --branch 37446-mpw_testing https://github.com/renode/renode

    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR/$RENODE_CLONE_DIR"
    git submodule update --init src/Infrastructure
    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"

    [ -e "$GITHUB_WORKSPACE/$VERILATOR_DIR/$BUILD_DIR" ] \
    || mkdir "$GITHUB_WORKSPACE/$VERILATOR_DIR/$BUILD_DIR"

    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR/$BUILD_DIR"
    cmake -DCMAKE_BUILD_TYPE=Release -DUSER_RENODE_DIR="$GITHUB_WORKSPACE/$VERILATOR_DIR/$RENODE_CLONE_DIR"  ..
    make libVtop
    cp libVtop.so "$GITHUB_WORKSPACE"/artifacts
    cd "$GITHUB_WORKSPACE"
}

run_test()
{
    echo run test
    # with:
      # renode-version: '1.13.1+20220918git57f09419'
      # tests-to-run: 'artifacts/*.robot'
      # artifacts-path: $GITHUB_WORKSPACE/artifacts
}


build_soc_configuration
build_renode_configuration
build_test
verilate_design
# run_test
