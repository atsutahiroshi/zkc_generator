#!/usr/bin/env bash

set -e

help_message () {
    printf "Usage:\n"
    printf "\t${0} <options> <wrl file>\n"
    printf "Arguments:\n"
    printf "\t<wrl file>             \toriginal robot model\n"
    printf "Options:\n"
    printf "\t--config [path]        \tconfig file to load\n"
    printf "\t--export [path]        \tfile path to export\n"
    printf "\t--build | --no-build   \tbuild choreonoid before running\n"
    printf "\t--kill | --no-kill     \tkill choreonoid automatically\n"
    printf "\t--kill-after-sec [sec] \tkill after [sec]sec\n"
    printf "\t--help                 \tshow this message\n"
}

#
# default values
#
TOP_DIR="$(cd "$(dirname "$0")" ; pwd -P)"

CONFIG_FILE="$TOP_DIR/config"
EXPORT_FILE_PATH=
ORIGINAL_FILE_PATH=
FLAG_BUILD=TRUE
FLAG_KILL=TRUE
KILL_AFTER_SEC=1
PROJECT_TEMPLATE="project/template.cnoid"
PYTHON_SCRIPT="script/load_robot.py"
TMP_PYTHON_SCRIPT="/tmp/load_robot.py"

check_args () {
    while [ $# -gt 0 ]; do
        case $1 in
            --config)         CONFIG_FILE=$2
                              shift 2
                              ;;
            --export)         EXPORT_FILE_PATH=$2
                              shift 2
                              ;;
            --build)          FLAG_BUILD=TRUE
                              shift
                              ;;
            --no-build)       FLAG_BUILD=FALSE
                              shift
                              ;;
            --kill)           FLAG_KILL=TRUE
                              shift
                              ;;
            --no-kill)        FLAG_KILL=FALSE
                              shift
                              ;;
            --kill-after-sec) KILL_AFTER_SEC=$2
                              shift 2
                              ;;
            -h|--help)        help_message
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
                ORIGINAL_FILE_PATH=$1
                shift
                ;;
        esac
    done

    # check if ORIGINAL_FILE_PATH specified, and exists
    if [ -z $ORIGINAL_FILE_PATH ]; then
        echo "please specify original wrl file"
        help_message
        exit 1
    fi
    if [ ! -f $ORIGINAL_FILE_PATH ]; then
        echo "$ORIGINAL_FILE_PATH does not exist!"
        exit 1
    fi
}

load_config () {
    if [ -f $CONFIG_FILE ]; then
        source $CONFIG_FILE
    else
        echo "$CONFIG_FILE does not exist!"
        echo "possibly you might run setup.sh"
        exit 1
    fi
}

build_choreonoid () {
    if [ $FLAG_BUILD = TRUE ]; then
        cd $CNOID_BUILD_DIR
        make -j4 || exit
        cd -
    fi
}

make_script () {
    SED_CMD="s%^ROBOT_FILE_NAME\ =\ \"\"%ROBOT_FILE_NAME\ =\ \"$ORIGINAL_FILE_PATH\"%g"
    sed -e "$SED_CMD" < $PYTHON_SCRIPT > $TMP_PYTHON_SCRIPT
}

run_choreonoid () {
    make_script
    if [ $FLAG_KILL = TRUE ]; then
        # run choreonoid on background to kill afterwards
        $CHOREONOID --python $TMP_PYTHON_SCRIPT $PROJECT_TEMPLATE &
    else
        $CHOREONOID --python $TMP_PYTHON_SCRIPT $PROJECT_TEMPLATE
    fi
}

kill_choreonoid () {
    if [ $FLAG_KILL = TRUE ]; then
        sleep ${KILL_AFTER_SEC}s
        pkill choreonoid
    fi
}

export_as_zkc () {
    if [ -z $EXPORT_FILE_PATH ]; then
        filename=$(basename $ORIGINAL_FILE_PATH)
        EXPORT_FILE_PATH="${filename%.*}.zkc"
    fi
    mv project/model.zkc $EXPORT_FILE_PATH
}

#
# main
#
check_args "$@"
load_config
build_choreonoid
run_choreonoid
kill_choreonoid
export_as_zkc
