#!/usr/bin/env bash
set -o nounset
set -o errexit
source bashcc.sh

echo "Haven't finished this one either..."
exit 1

function func1() {
}

function func2() {
}

function func3() {
}

function __ref() {
}

function ref_make() {
    initial_value=$1; shift
    prompt=$(make_prompt)
    response=$(run $prompt __ref $prompt)
    if [[ $response =~ $yield_re ]]
    then
        continuation="${BASH_REMATCH[1]}"
        data="${BASH_REMATCH[2]}"
        # oh wait, this isn't state, this requires passing the continuation around, because it keeps changing.
        response=$(invoke $prompt $continuation "restarted")
    elif [[ $response =~ $return_re ]]
    then
        file="${BASH_REMATCH[1]}"
        echo "returned??? from a reference??? that's bad and wrong!"
        echo "message we got was:"
        echo "-----------"
        cat $file
        echo "-----------"
        exit 1
    else
        echo "disaster has struck, we got some incomprehensible message"
        echo "got $response"
        exit 1
    fi
}

function ref_init() {
    prompt=$(make_prompt)
    response=$(run $prompt "$@")
    while :;
    do
        if [[ $response =~ $yield_re ]]
        then
  	    continuation="${BASH_REMATCH[1]}"
  	    message="${BASH_REMATCH[2]}"
  	    echo "yielded with message $message"
  	    echo "invoking again"
  	    response=$(invoke $prompt $continuation "restarted")
        elif [[ $response =~ $return_re ]]
        then
  	    file="${BASH_REMATCH[1]}"
  	    echo "returned! we're done!"
  	    echo "message we got was:"
  	    echo "-----------"
  	    cat $file
  	    echo "-----------"
  	    break
        else
  	    echo "disaster has struck, we got some incomprehensible message"
  	    echo "got $response"
  	    exit 1
        fi
    done
}
