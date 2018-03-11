#!/bin/bash
set -o nounset
set -o errexit

statedir=$(mktemp -d --tmpdir bashcc.XXXXXX)

function name() {
    template=$1; shift
    mktemp -u --tmpdir=$statedir $template
}

function proc_create() {
    procfile=$(name proc.XXXX)
    touch $procfile
    echo $procfile
}

function proc_monitor() {
    procfile=$1; shift
    echo $BASHPID > $procfile
    exec "$@"
}

function proc_kill() {
    procfile=$1; shift
    kill $(cat $procfile) 2>/dev/null || true
}

function file_size() {
    file=$1; shift
    stat --printf="%s" $file
}

function file_wait_for_one_line() {
    file=$1; shift
    size=$1; shift
    bytecount=$((size + 1))
    proc=$(proc_create)
    proc_monitor $proc tail --bytes=+$bytecount --follow $file | { head -n1; proc_kill $proc; }
}

function msg_send() {
    file=$1; shift
    echo "$@" >> $file
}

# raise and continue should be separate
# this way only allows one continuation to be blocked at a prompt at a time.
# we can't switch between continuations!

# we need to send the continuation file to the prompt
# and then block on it

# and maybe msg_call also should be broken up?

# the continuation file changes each time we yield.

function msg_call() {
    prompt=$1; shift
    continue_size=$(file_size $prompt/continue)
    msg_send $prompt/raise "$@"
    file_wait_for_one_line $prompt/continue $continue_size
}

function msg_receive() {
    prompt=$1; shift
    raise_size=$(file_size $prompt/raise)
    file_wait_for_one_line $prompt/raise $raise_size
}

function msg_reply() {
    prompt=$1; shift
    msg_send $prompt/continue "$@"
}

function make_prompt() {
    prompt=$(name prompt.XXXX)
    mkdir $prompt
    touch $prompt/raise
    touch $prompt/continue
    echo $prompt
}

function wrap_return() {
    prompt=$1; shift
    stdout=$(name stdout.XXXX)
    "$@" $prompt > $stdout
    msg_send $prompt/raise "return: $stdout"
}

function run() {
    # create a prompt
    # fork off child
    # block on prompt
    # and on child?
    proc=$(proc_create)
    prompt=$(make_prompt)
    proc_monitor $proc wrap_return $prompt "$@" &
    tail -c+0 -f $prompt/raise
}

function yield() {
    prompt=$1; shift
    msg_call $prompt "$@"
}


file=$1; shift
size=$(file_size $file)
file_wait_for_one_line $file $size
