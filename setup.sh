#!/usr/bin/env bash

set -e

help_message () {
    printf "Usage:\n"
    printf "\t${0} <options>\n"
    printf "Options:\n"
    printf "\t--config-export [path]\tconfig file to save\n"
    printf "\t--config-load [path]  \tconfig file to load\n"
    printf "\t--cnoid-dir [path]    \tchoreonoid directory\n"
    printf "\t--cnoid-share-dir [path] \tchoreonoid share directory\n"
    printf "\t--cnoid-build-dir [path] \tchoreonoid build directory\n"
    printf "\t--branch [name]       \tbranch name for working\n"
    printf "\t--patch-dir [path]    \tdirectory that contains patches\n"
}

#
# default values
#
TOP_DIR="$(cd "$(dirname "$0")" ; pwd -P)"

FLAG_CONFIG_EXPORT_GIVEN=FALSE
FLAG_CONFIG_LOAD_GIVEN=FALSE
CONFIG_FILE_EXPORT="$TOP_DIR/config"
CONFIG_FILE_LOAD="$TOP_DIR/config"

CNOID_DIR="$TOP_DIR/choreonoid"
CNOID_SHARE_DIR="$CNOID_DIR/share"
CNOID_MODEL_DIR="$CNOID_SHARE_DIR/model"
CNOID_PROJECT_DIR="$CNOID_SHARE_DIR/project"
CNOID_EXT_DIR="$CNOID_DIR/ext"
CNOID_BUILD_DIR="$CNOID_DIR/build"
CHOREONOID="$CNOID_BUILD_DIR/bin/choreonoid"

BRANCH_NAME="zkc_generator"
PATCH_DIR="$TOP_DIR/patches"

check_args () {
    while [ $# -gt 0 ]; do
        case $1 in
            --config-export)   FLAG_CONFIG_EXPORT_GIVEN=TRUE
                               CONFIG_FILE_EXPORT=$2
                               shift 2
                               ;;
            --config-load)     FLAG_CONFIG_LOAD_GIVEN=TRUE
                               CONFIG_FILE_LOAD=$2
                               shift 2
                               ;;
            --cnoid-dir)       CNOID_DIR=$2
                               shift 2
                               ;;
            --cnoid-share-dir) CNOID_SHARE_DIR=$2
                               shift 2
                               ;;
            --cnoid-build-dir) CNOID_BUILD_DIR=$2
                               shift 2
                               ;;
            --branch)          BRANCH_NAME=$2
                               shift 2
                               ;;
            --patch-dir)       PATCH_DIR=$2
                               shift 2
                               ;;
            -h|--help)         help_message
                               exit 0
                               ;;
            --) shift
                break
                ;;
            --*|-*)
                echo "unrecognized option: $1"
                help_message
                exit 1
                ;;
            *)
                shift
                ;;
        esac
    done

    # check if config file should be exported
    FLAG_EXPORT=FALSE
    if [ $FLAG_CONFIG_EXPORT_GIVEN = TRUE ]; then
        FLAG_EXPORT=TRUE
    else
        if [ $FLAG_CONFIG_LOAD_GIVEN = FALSE -a ! -f $CONFIG_FILE_EXPORT ]; then
            FLAG_EXPORT=TRUE
        fi
    fi

    # check which config file should be loaded
    # when --config-load was not specified
    if [ $FLAG_CONFIG_LOAD_GIVEN = FALSE ]; then
        if [ $FLAG_CONFIG_EXPORT_GIVEN = TRUE ]; then
            CONFIG_FILE_LOAD=$CONFIG_FILE_EXPORT
        fi
    fi
}

print_var () {
    eval "tmp=\$$1"
    echo "$1=\"$tmp\""
}

print_vars_for_debug () {
    print_var "FLAG_CONFIG_EXPORT_GIVEN"
    print_var "FLAG_CONFIG_LOAD_GIVEN"
    print_var "CONFIG_FILE_EXPORT"
    print_var "CONFIG_FILE_LOAD"
    print_var "TOP_DIR"
    print_var "CNOID_DIR"
    print_var "CNOID_SHARE_DIR"
    print_var "CNOID_MODEL_DIR"
    print_var "CNOID_PROJECT_DIR"
    print_var "CNOID_EXT_DIR"
    print_var "CNOID_BUILD_DIR"
    print_var "CHOREONOID"
    print_var "BRANCH_NAME"
    print_var "PATCH_DIR"
}

make_config () {
    print_var "TOP_DIR"
    print_var "CNOID_SHARE_DIR"
    print_var "CNOID_MODEL_DIR"
    print_var "CNOID_PROJECT_DIR"
    print_var "CNOID_EXT_DIR"
    print_var "CNOID_BUILD_DIR"
    echo ""
    print_var "CHOREONOID"
}

export_config () {
    if [ $FLAG_EXPORT = TRUE ]; then
        make_config > $CONFIG_FILE_EXPORT
    fi
}

load_config () {
    if [ -f $CONFIG_FILE_LOAD ]; then
        source $CONFIG_FILE_LOAD
    else
        echo "$CONFIG_FILE_LOAD does not exist!"
        exit 1
    fi
}

git_branch_exists () {
    git rev-parse --verify $1 &>/dev/null
    # if exists, $? == 0
}

git_checkout () {
    if git_branch_exists $1; then
        git checkout $1
    else
        git checkout -b $1 master
    fi
}

git_checkout_cnoid () {
    git_checkout $BRANCH_NAME
}

can_patch_be_applied () {
    # patch -p1 -N --dry-run --silent < $1 &>/dev/null
    git apply --check $1 &>/dev/null
    # if no error detected, $? == 0
}

apply_patch () {
    if can_patch_be_applied $1; then
        # patch -p1 -N --silent < $1
        git am --whitespace=nowarn --quiet < $1
        echo "done."
    else
        echo "skipped."
    fi
}

apply_patches_in_dir () {
    for i in "$1"/*; do
        echo -n "applying $(basename $i)..."
        apply_patch $i
    done
}

find_roki_dir () {
    ROKI_INCLUDE=$(roki-config -I)
    SED_CMD1="sed -e s/^-I//g"
    SED_CMD2="sed -e s/\/include$//g"
    ROKI_DIR=`echo $ROKI_INCLUDE | $SED_CMD1 | $SED_CMD2`
    echo $ROKI_DIR
}

cmake_option() {
    echo "-D${1}=${2} "
}
CMAKE_OPTIONS=\
$(cmake_option BUILD_ROKI_PLUGIN ON)\
$(cmake_option ROKI_DIR $(find_roki_dir))


#
# main
#
CWD=$(pwd)
check_args "$@"

cd $TOP_DIR
export_config
load_config

cd $CNOID_DIR
git_checkout $BRANCH_NAME
apply_patches_in_dir $PATCH_DIR

mkdir -p $CNOID_BUILD_DIR
cd $CNOID_BUILD_DIR
cmake $CMAKE_OPTIONS -Wno-dev ..

cd $CWD
