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

# raise and continue should be separate
# this way only allows one continuation to be blocked at a prompt at a time.
# we can't switch between continuations!

# we need to send the continuation file to the prompt
# and then block on it

# and maybe msg_call also should be broken up?

# the continuation file changes each time we yield.
function msg_new() {
    template=$1; shift
    msgqueue=$(name continuation.XXXX)
    touch $msgqueue
    echo $msgqueue
}

function msg_send() {
    file=$1; shift
    echo "$@" >> $file
}

function msg_receive_once() {
    msgqueue=$1; shift
    file_wait_for_one_line $msgqueue 0
}

function msg_receive_new() {
    msgqueue=$1; shift
    size=$1; shift
    file_wait_for_one_line $msgqueue $size
}

function msg_old_marker() {
    msgqueue=$1; shift
    file_size $msgqueue
}

function run_something() {
    prompt=$1; shift
    prompt_old_marker=$(msg_old_marker $prompt)
    msg_send
    # do thing
    msg_receive_new $prompt $prompt_old_marker
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
    msg_send $prompt "return: $stdout"
}

function push_subcont() {
    prompt=$1; shift
    continuation=$1; shift
}

function run() {
    # create a prompt
    # fork off child
    # block on prompt
    # and on child?
    proc=$(proc_create)
    prompt=$(make_prompt)
    proc_monitor $proc wrap_return $prompt "$@" &
    # clean this guy up somehow??
    # clean up the running process, I mean
    # no just leave him around
    
    tail -c+0 -f $prompt/raise
}

function yield() {
    prompt=$1; shift
    continuation=$(msg_new continuation.XXXX)
    msg_send $prompt "yield: $continuation" "$@"
    msg_receive_once $continuation
}

file=$1; shift
size=$(file_size $file)
file_wait_for_one_line $file $size
