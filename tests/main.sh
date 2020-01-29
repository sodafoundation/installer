#!/bin/bash

# Copyright 2020 The OpenSDS Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

TOP_DIR=$(cd $(dirname "$0") && cd .. && pwd)

source $TOP_DIR/tests/utils.sh
source $TOP_DIR/tests/config.sh
source $TOP_DIR/tests/verify.sh
source $TOP_DIR/tests/functional.sh
source $TOP_DIR/tests/unit.sh

# usage function
function usage()
{
   cat << HEREDOC

   Usage: main.sh [ options ]

   optional arguments:
     -h, --help           show this help message and exit
     -a                   Automatically run and verify all tests
     -i                   Interactively run tests
     -c                   Clean and purge current installation
     -d                   Increase the verbosity of the bash/ansible script
     -v                   Verify opensds installations

HEREDOC
}  


function manual_test()
{
    testcase="Run one OpenSDS ansible installer test"
    verify="Verify previous OpenSDS Installation"
    purge="Purge previous OpenSDS Installation"
    quit="Quit"

    echo -e "\nSelect from below actions (Enter a number between 1 and 3)\n"

    select choice in "$testcase" "$verify" "$purge" "$quit"
    do
        case $choice in
            $testcase)
                echo -e "\n Testcase RUN"
                read -p "Enter the test number <01-22, 101-300>: " test_id
                echo -e "\nTesting $test_id"
                test_opensds_$test_id
                ;;
            $verify)
                echo -e "\n Installation verify"
                verify
                ;;
            $purge)
                echo -e "\n Installation clean and purge"
                purge_installation
                ;;
            $quit)
                break
                ;;
            *)
                echo -e "\n==> Enter a number between 1 and 3"
                ;;
        esac
    done
}


OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts ":h?aicvd" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    a)  automatic="1"
        ;;
    i)  interactive="1"
        ;;
    c)  clean="1"
        ;;
    v)  verify="1"
        ;;
    d)  debug="1"
        ;;
    :)  echo "option -$OPTARG requires an argumnet"
        usage
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift


# echo "verify=$verify, automatic=$automatic, clean=$clean, interactive=$interactive, debug=$debug, Leftovers: $@"

if [ "$clean" = "1" ]; then
    purge_installation
    exit
fi

if [ "$verify" = "1" ]; then
    verify
    exit
fi

if [ "$interactive" = "1" ]; then
    manual_test 
    exit
fi

if [ "$automatic" = "1" ]; then

    test_opensds_01 && verify && purge_installation

    # test_opensds_02 && purge_installation
    # test_opensds_03 && purge_installation
    # test_opensds_04 && purge_installation
    # test_opensds_05 && purge_installation
    # test_opensds_06 && purge_installation

    # test_opensds_07 && purge_installation
    # test_opensds_08 && purge_installation
    # test_opensds_09 && purge_installation
    # test_opensds_10 && purge_installation
    # test_opensds_11 && purge_installation
    # test_opensds_12 && purge_installation

    # test_opensds_13 && purge_installation
    # test_opensds_14 && purge_installation
    # test_opensds_15 && purge_installation
    # test_opensds_16 && purge_installation
    # test_opensds_17 && purge_installation
    # test_opensds_18 && purge_installation

    # test_opensds_19 && purge_installation
    # test_opensds_20 && purge_installation
    # test_opensds_21 && purge_installation
    # test_opensds_22 && purge_installation

    # test_opensds_101 && purge_installation
    # test_opensds_102 && purge_installation
    # test_opensds_103 && purge_installation
    # test_opensds_104 && purge_installation
    # test_opensds_105 && purge_installation
    # test_opensds_106 && purge_installation
    # test_opensds_107 && purge_installation
    # test_opensds_108 && purge_installation
    # test_opensds_109 && purge_installation
fi
