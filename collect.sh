#!/bin/bash

: '

Copyright (C) 2020 Rafael Sene

Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
    Rafael Sene <rpsene@gmail.com> - Initial implementation.
'
# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT
function ctrl_c() {
        echo "Bye!"
}

TODAY=$(date +'%m%d%Y')
TIME=$(date +"%H%M%S%Z")
ASSIGNEES=()

RH_BZ_CSV_QUERY=https://bugzilla.redhat.com/buglist.cgi\?bug_status\=__open__\&classification\=Red\%20Hat\&component\=Multi-Arch\&list_id\=11455354\&product\=OpenShift\%20Container\%20Platform\&query_format\=advanced\&ctype\=csv

function check_dependencies() {
	# Check the script dependencies
	local DEPENDENCIES=(curl jq awk)
	for dep in "${DEPENDENCIES[@]}"
	do
		if ! command -v $dep &> /dev/null; then
				echo "$dep could not be found, exiting!"
				exit
		fi
	done
}

function prepare () {
    if [ ! -d "./tmp" ]; then
        mkdir -p "./tmp"
    else
        rm -rf ./tmp/*
    fi
}

function collect_bugs (){
    curl -o "./tmp/rh-ocp-bugs-$TODAY-$TIME.tmp" "$RH_BZ_CSV_QUERY" > /dev/null 2>&1
    while read line; do
        if [[ ! $line == *"bug_id"* ]]; then
            echo "$line" | tr -d "\"" |  tr -d "\%" >> "./tmp/rh-ocp-bugs-$TODAY-$TIME.csv"
        fi
    done < "./tmp/rh-ocp-bugs-$TODAY-$TIME.tmp"
    rm -f "./tmp/rh-ocp-bugs-$TODAY-$TIME.tmp"
}

function count-assignees() {
    echo
    echo "*************************************************"
    while read line; do
        ASSIGNEE=$(echo "$line" | awk '{split($0,a,","); print a[4]}')
        if [ -z "$ASSIGNEE" ];then
            ASSIGNEE="NOT ASSIGNED"
        fi
        ASSIGNEES[${#ASSIGNEES[@]}]=$ASSIGNEE
    done < "./tmp/rh-ocp-bugs-$TODAY-$TIME.csv"
    printf '%s\n' "${ASSIGNEES[@]}" | sort | uniq -c | sort -nr
}

function list-bugs-and-assignees() {
    echo
    echo "*************************************************"
    while read line; do
        BUG_ID=$(echo "$line" | awk '{split($0,a,","); print a[1]}')
        ASSIGNEE=$(echo "$line" | awk '{split($0,a,","); print a[4]}')
        if [ -z "$ASSIGNEE" ];then
            ASSIGNEE="NOT ASSIGNED"
        fi
        STATUS=$(echo "$line" | awk '{split($0,a,","); print a[5]}')
        URL="https://bugzilla.redhat.com/show_bug.cgi?id=$BUG_ID" 
        echo "$ASSIGNEE: $STATUS,$BUG_ID,$URL"
    done < "./tmp/rh-ocp-bugs-$TODAY-$TIME.csv"
}

function cleanup () {
    rm -rf ./tmp/
}

function run (){
    check_dependencies
    prepare
    collect_bugs
    count-assignees
    list-bugs-and-assignees
    cleanup
}

run "@"
