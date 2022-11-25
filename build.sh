#!/bin/bash

set -e

BASE_DIR=${GITHUB_WORKSPACE:-$(pwd)}
VERILATOR_DIR=${VERILATOR_DIR:-verilator}
RENODE_CLONE_DIR=${RENODE_CLONE_DIR:-renode}
BUILD_DIR=${BUILD_DIR:-build}

DESIGN_NAME_DEFAULT=aes
DESIGN_NAME=${DESIGN_NAME:-${DESIGN_NAME_DEFAULT}}
DESIGN_FILES="$DESIGN_NAME.v"
TEST_NAME_DEFAULT=aes_test
TEST_NAME=${TEST_NAME:-${TEST_NAME_DEFAULT}}
CLASS_NAME_DEFAULT=Vaes
CLASS_NAME=${CLASS_NAME:-${CLASS_NAME_DEFAULT}}
INCLUDE_DEFAULT=Vaes.h
INCLUDE=${INCLUDE:-${INCLUDE_DEFAULT}}

build_test_nodocker()
{
    echo "\n\n\n build_test_nodocker \n\n\n"

    export TARGET_PATH=$(pwd)
    export TOOLS="$BASE_DIR"/riscv-unknown-elf-gcc
    export GCC_PREFIX=riscv64-unknown-elf

    export DESIGNS=${TARGET_PATH}
    export CORE_VERILOG_PATH=${TARGET_PATH}/mgmt_core_wrapper/verilog
    export MCW_ROOT=${TARGET_PATH}/mgmt_core_wrapper

    # execute all passed commands

    sh -c "$*"
}

usage()
{
    echo "$0 [-v DESIGN_NAME ] [-t TEST_NAME] [-i FILE] [-I INCLUDE] [-c CLASS] [-TV] [MODE]"
    echo ""
    echo " -v DESIGN_NAME   - Set design to use, default is $DESIGN_NAME_DEFAULT"
    echo " -t TEST_NAME     - Set test name to use, default is $TEST_NAME_DEFAULT"
    echo " -f MAIN_FILE     - Set specific verilator file to use"
    echo " -i EXTRA_FILE    - Copy additional file to $VERILATOR_DIR"
    echo " -I INCLUDE       - Set include in sim_main.cpp, default is $INCLUDE_DEFAULT"
    echo " -C CLASS         - Set top class in sim_main.cpp, default is $CLASS_NAME_DEFAULT"
    echo " -V               - Display all possible design names"
    echo " -T               - Display all possible test names"
    echo " MODE             - Function to run, default is ALL"
    echo "      soc_configuration       - Build soc configuration"
    echo "      renode_configuration    - Build renode configuration"
    echo "      test                    - Build test"
    echo "      verilate_design         - Verilate design"
    echo "      ALL                     - Run all functions above"
}

build_soc_configuration()
{
    echo "\n\n\n build_soc_configuration \n\n\n"
    pushd "$BASE_DIR"/design/mgmt_core_wrapper/litex >/dev/null
    pip install -r requirements.txt
    make mgmt_soc
    cp csr.json "$BASE_DIR"/artifacts
    popd >/dev/null
}

build_renode_configuration()
{
    echo "\n\n\n build_renode_configuration \n\n\n"
    python3 "$BASE_DIR"/scripts/litex_json2renode.py --auto-align dff --auto-align sram --repl design.repl "$BASE_DIR"/artifacts/csr.json
    cat design.repl scripts/design-addend.repl > "$BASE_DIR"/artifacts/design.repl
    cp scripts/design.resc "$BASE_DIR"/artifacts
    cp scripts/design.robot "$BASE_DIR"/artifacts
}

build_test()
{
    echo "\n\n\n build_test \n\n\n"
    pushd "$BASE_DIR"/design >/dev/null
    make -f "${BASE_DIR}"/design.Makefile verify-"$TEST_NAME"-elf
    cp "$BASE_DIR"/design/verilog/dv/"$TEST_NAME"/"$TEST_NAME".elf "$BASE_DIR"/artifacts/test.elf
    popd >/dev/null
}

verilate_design()
{
    echo "\n\n\n verilate_design \n\n\n"
    echo "DESIGN NAME:     $DESIGN_NAME"

    pushd "$BASE_DIR/$VERILATOR_DIR" >/dev/null
    [ -n "$DESIGN_NAME" ] \
    && cp "$BASE_DIR"/design/verilog/rtl/"$DESIGN_NAME"/generated/"$DESIGN_NAME".v .

    # clone renode
    [ -e "$BASE_DIR/$VERILATOR_DIR/$RENODE_CLONE_DIR" ] \
    && {
        pushd "$BASE_DIR/$VERILATOR_DIR/$RENODE_CLONE_DIR" >/dev/null
        git pull --depth=1
        popd >/dev/null
    } \
    || git clone --depth=1 --branch 37446-mpw_testing https://github.com/renode/renode

    pushd "$BASE_DIR/$VERILATOR_DIR/$RENODE_CLONE_DIR" >/dev/null
    git submodule update --init src/Infrastructure
    popd >/dev/null

    [ -e "$BASE_DIR/$VERILATOR_DIR/$BUILD_DIR" ] \
    || mkdir "$BASE_DIR/$VERILATOR_DIR/$BUILD_DIR"

    sed "s/\$BUILD_INCLUDE/$INCLUDE/;s/\$BUILD_CLASS/$CLASS_NAME/g" "$BASE_DIR"/sim_main.cpp.template > "$BASE_DIR/$VERILATOR_DIR"/sim_main.cpp

    pushd "$BASE_DIR/$VERILATOR_DIR/$BUILD_DIR" >/dev/null
    cmake -DVTOP="${DESIGN_FILES}" -DCMAKE_BUILD_TYPE=Release -DUSER_RENODE_DIR="$BASE_DIR/$VERILATOR_DIR/$RENODE_CLONE_DIR"  ..
    make libVtop
    cp libVtop.so "$BASE_DIR"/artifacts
    popd >/dev/null

    popd >/dev/null
}

set -- $(getopt "v:t:TVf:i:c:I:" "$@") || usage ""
while :; do
    case "$1" in
        -v)
            shift; DESIGN_NAME="$1"
            DESIGN_FILES="$DESIGN_NAME.v"
            ;;
        -t) shift; TEST_NAME="$1" ;;
        -c) shift; CLASS_NAME="$1" ;;
        -I) shift; INCLUDE="$1" ;;
        -V)
            find design/verilog/rtl/* -maxdepth 0 -type d \
            | sed 's|design/verilog/rtl/||; /example/d'

            exit
            ;;
        -T)
            find design/verilog/dv/* -maxdepth 0 -type d \
            | sed 's|design/verilog/dv/||'

            exit
            ;;
        -f)
            shift;
            absolute_path="$(realpath "$1")"
            DESIGN_FILES="$absolute_path"
            cp $absolute_path $BASE_DIR/$VERILATOR_DIR
            ;;
        -i)
            shift;
            absolute_path="$(realpath "$1")"
            cp $absolute_path $BASE_DIR/$VERILATOR_DIR
            ;;
        --) break;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done
shift

case "${1:-ALL}" in
    soc_configuration) build_soc_configuration ;;
    renode_configuration) build_renode_configuration ;;
    test) build_test ;;
    verilate_design) verilate_design ;;
    ALL)
        build_soc_configuration
        build_renode_configuration
        build_test
        verilate_design
    ;;
    test_nodocker)
        shift
        build_test_nodocker $*
        break
        ;;
    *) usage ;;
esac
