#!/usr/bin/env bash
set -o nounset
set -o errexit
source bashcc.sh

function raise() {
    yield $exception_handler "$@"
}

function liker() {
    if [[ $1 -eq 12 ]];
    then raise "I don't like $1!!!"
    else echo "I like $1" >&2
    fi
}

function evaluator() {
    seq 4 | while read -r; do liker $REPLY; done
    seq 10 | while read -r; do liker $REPLY; done
    seq 14 | while read -r; do liker $REPLY; done
    echo "reached end of func3" >&2
}

function try() {
    exception_handler=$(make_prompt)
    response=$(run $exception_handler "$@")
    while :;
    do
        if [[ $response =~ $yield_re ]]
        then
  	    continuation="${BASH_REMATCH[1]}"
  	    exception="${BASH_REMATCH[2]}"
  	    echo "exception was thrown! setting 'exception'"
            echo "exiting non-zero"
            return 1
        elif [[ $response =~ $return_re ]]
        then
  	    file="${BASH_REMATCH[1]}"
  	    echo "returned! we're done!"
  	    echo "message we got was:"
  	    echo "-----------"
  	    cat $file
  	    echo "-----------"
  	    return 0
        else
  	    echo "disaster has struck, we got some incomprehensible message"
  	    echo "got $response"
  	    exit 1
        fi
    done
}

function main() {
    try evaluator || {
        # got exception
        echo "exception was $exception"
    }
}

main
