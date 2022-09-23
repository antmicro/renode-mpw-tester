#!/bin/sh

set -e

GITHUB_WORKSPACE=${GITHUB_WORKSPACE:-$(pwd)}
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

usage()
{
    echo "$0 [-v DESIGN_NAME ] [-t TEST_NAME] [-i FILE] [-I INCLUDE] [-c CLASS] [-TV] [MODE]"
    echo ""
    echo " -v DESIGN_NAME   - Set design to use, default is $DESIGN_NAME_DEFAULT"
    echo " -t TEST_NAME     - Set test name to use, default is $TEST_NAME_DEFAULT"
    echo " -f FILE          - Set specific verilator file to use"
    echo " -i FILE          - Copy additional file to $VERILATOR_DIR"
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


    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR"
    [ -n "$DESIGN_NAME" ] \
    && cp "$GITHUB_WORKSPACE"/design/verilog/rtl/"$DESIGN_NAME"/generated/"$DESIGN_NAME".v .
    
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

    sed "s/\$BUILD_INCLUDE/$INCLUDE/;s/\$BUILD_CLASS/$CLASS_NAME/g" "$GITHUB_WORKSPACE"/sim_main.cpp.template > "$GITHUB_WORKSPACE/$VERILATOR_DIR"/sim_main.cpp

    cd "$GITHUB_WORKSPACE/$VERILATOR_DIR/$BUILD_DIR"
    cmake -DVTOP="${DESIGN_FILES}" -DCMAKE_BUILD_TYPE=Release -DUSER_RENODE_DIR="$GITHUB_WORKSPACE/$VERILATOR_DIR/$RENODE_CLONE_DIR"  ..
    make libVtop
    cp libVtop.so "$GITHUB_WORKSPACE"/artifacts
    cd "$GITHUB_WORKSPACE"

    echo END
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
            base_path="$(dirname "$1")"
            file_name="$(basename "$1")"
            cd "$base_path"
            absolute_path="$(pwd)/$file_name"
            cd "$OLDPWD"
            echo $absolute_path
            DESIGN_FILES="$absolute_path"
            cp $absolute_path $GITHUB_WORKSPACE/$VERILATOR_DIR
            ;;
        -i) 
            shift; 
            base_path="$(dirname "$1")"
            file_name="$(basename "$1")"
            cd "$base_path"
            absolute_path="$(pwd)/$file_name"
            cd "$OLDPWD"
            echo $absolute_path
            cp $absolute_path $GITHUB_WORKSPACE/$VERILATOR_DIR
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
    *) usage ;;
esac

# run_test
