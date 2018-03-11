#!/usr/bin/env bash
set -o nounset
set -o errexit
source bashcc.sh

# just some arbitrary yielding function
function some_func() {
    prompt=$1; shift
    yield $prompt "hello"
    yield $prompt "hello2"
    echo "bye"
}

prompt=$(make_prompt)
dummy_run_with_prompt $prompt some_func $prompt
