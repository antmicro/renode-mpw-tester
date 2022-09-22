#!/bin/sh

set -e

GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}

DESIGN_NAME_DEFAULT=aes
DESIGN_NAME=${DESIGN_NAME:-${DESIGN_NAME_DEFAULT}}
TEST_NAME_DEFAULT=aes_test
TEST_NAME=${TEST_NAME:-${TEST_NAME_DEFAULT}}

usage()
{
    echo "$0 [-v DESIGN_NAME ] [-t TEST_NAME] [-T]"
    echo ""
    echo " -v DESIGN_NAME - Set design to use, default is $DESIGN_NAME_DEFAULT"
    echo " -t TEST_NAME - Set test name to use, default is $TEST_NAME_DEFAULT"
    echo " -V - Display all possible design names"
    echo " -T - Display all possible test names"
}

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
    echo "DESIGN NAME:     $DESIGN_NAME"

    VERILATOR_DIR=${VERILATOR_DIR:-verilator}
    RENODE_CLONE_DIR=${RENODE_CLONE_DIR:-renode}
    BUILD_DIR=${BUILD_DIR:-build}

    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"
    cp "$GITHUB_WORKSPACE"/design/verilog/rtl/"$DESIGN_NAME"/generated/"$DESIGN_NAME".v .
    
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
    cmake -DVTOP="${DESIGN_NAME}".v -DCMAKE_BUILD_TYPE=Release -DUSER_RENODE_DIR="$GITHUB_WORKSPACE/$VERILATOR_DIR/$RENODE_CLONE_DIR"  ..
    make libVtop
    cp libVtop.so "$GITHUB_WORKSPACE"/artifacts
    cd "$GITHUB_WORKSPACE"

    echo END
}



while getopts "v:t:TV" option; do
    case "$option" in
        v) DESIGN_NAME="$OPTARG" ;;
        t) TEST_NAME="$OPTARG" ;;
        V) 
            find design/verilog/rtl/* -maxdepth 0 -type d \
            | sed 's|design/verilog/rtl/||; /example/d'

            exit
            ;;
        T) 
            find design/verilog/dv/* -maxdepth 0 -type d \
            | sed 's|design/verilog/dv/||'

            exit
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

build_soc_configuration
build_renode_configuration
build_test
verilate_design
# run_test
