#!/usr/bin/env bash
set -o nounset
set -o errexit
source bashcc.sh

echo "Oops I lied, I didn't include coroutines in the paper because I haven't finished it yet."
echo "But I am pretty sure it would work."
exit 1

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

# recv
recv_re='recv:'
# send a continuation???
spawn_re='spawn: (.*)'
# send: [arbitrary string message]
send_re='send: (.*)'

# pop_array:
# val="${array[0]}"
# array=("${array[@]:1}")
function spawn() {
    prompt=$1; shift
    {
	"$@";
	# Translate the return of the function into a message to the prompt.
        file_send_line $prompt "return: $stdout";
    } >$stdout </dev/null &
    file_wait_for_one_line $prompt $prompt_size
    # return a continuation and a thunk
    # can't return thunks, so return two continuations instead.
}


function run_all() {
    channel=$(make_prompt)
    response=$(run $exception_handler "$@")
    declare -a recv_blocked
    while :;
    do
        if [[ $response =~ $yield_re ]]; then
  	    continuation="${BASH_REMATCH[1]}"
  	    value="${BASH_REMATCH[2]}"
            if [[ $value =~ $recv_re ]]; then
                # spin until we get a new value
                # append to recv_blocked
            elif [[ $value =~ $send_re ]]; then
  	        channel="${BASH_REMATCH[1]}"
  	        msg="${BASH_REMATCH[2]}"
            fi
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
