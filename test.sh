#!/bin/bash

set -e

BASE_DIR=${GITHUB_WORKSPACE:-$(pwd)}

RENODE_VERSION_DEFAULT=1.13.1+20220918git57f09419
RENODE_VERSION=${RENODE_VERSION:-$RENODE_VERSION_DEFAULT}
RENODE_DIR_DEFAULT="."
RENODE_DIR=${RENODE_DIR:-$RENODE_DIR_DEFAULT}

usage()
{
    echo "$0 [-v VERSION ] [-d DIRECTORY ] [-T]"
    echo ""
    echo " -v VERSION - Set Renode version to use, default is $RENODE_VERSION_DEFAULT"
    echo " -d DIRECTORY - Set Renode directory to use, default is $RENODE_DIR_DEFAULT"
}

run_test()
{
    renode-run -a "$RENODE_DIR" download -d "$RENODE_VERSION"
    renode-run -a "$RENODE_DIR" test -- -r "$BASE_DIR"/artifacts "$BASE_DIR"/artifacts/*.robot
}

while getopts "v:d:" option; do
    case "$option" in
        v) RENODE_VERSION="$OPTARG";;
        d) RENODE_DIR="$OPTARG";;
        *)
            usage
            exit 1
            ;;
    esac
done

run_test
