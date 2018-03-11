#!/usr/bin/env bash
set -o nounset
set -o errexit
source bashcc.sh

# a hack to do early return without having to case on it in the handler
function early_return() {
    prompt=$1; shift
    file=$(name early_return.XXXX)
    echo "$@" > $file
    file_send_line $prompt "return: $file"
    exit 0
}

function recursive_multiply_args() {
    prompt=$1; shift
    echo "invoked with" "$@" >&2
    first=$1; shift
    if [[ $# -eq 0 ]]; then
	echo "base case with $first" >&2
	echo $first
    elif [[ $first -eq 0 ]]; then
	# comment out this elif case to see the full recursion
	early_return $prompt 0
    else
	echo "recursing on" "$@" >&2
	rest=$(recursive_multiply_args $prompt "$@")
	echo $(( first * rest ))
    fi
}

prompt=$(make_prompt)
dummy_run_with_prompt $prompt recursive_multiply_args $prompt 1 2 0 4 5
