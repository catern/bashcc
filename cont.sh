#!/bin/bash
set -o nounset
set -o errexit

statedir=$(mktemp -d --tmpdir bashcc.XXXXXX)

function name() {
    template=$1; shift
    mktemp -u --tmpdir=$statedir $template
}

#### Process monitoring functions
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

#### File-based messaging functions
function file_size() {
    file=$1; shift
    stat --printf="%s" $file
}

function file_send_line() {
    file=$1; shift
    echo "$@" >> $file
}

function file_wait_for_one_line() {
    file=$1; shift
    size=$1; shift
    bytecount=$((size + 1))
    proc=$(proc_create)
    proc_monitor $proc tail --bytes=+$bytecount --follow $file | { head -n1; proc_kill $proc; }
}
# file=$1; shift
# size=$(file_size $file)
# file_wait_for_one_line $file $size

#### Continuation functions
function make_prompt() {
    prompt=$(name prompt.XXXX)
    touch $prompt
    echo $prompt
}

function invoke() {
    prompt=$1; shift
    continuation=$1; shift
    prompt_size=$(file_size $prompt)
    file_send_line $continuation "$@"
    file_wait_for_one_line $prompt $prompt_size
}

function run() {
    prompt=$1; shift
    prompt_size=$(file_size $prompt)
    stdout=$(name stdout.XXXX)
    {
	"$@" $prompt;
	# Translate the return of the function into a message to the prompt.
        file_send_line $prompt "return: $stdout";
    } >$stdout </dev/null &
    file_wait_for_one_line $prompt $prompt_size
}

function yield() {
    prompt=$1; shift
    continuation=$(name continuation.XXXX)
    touch $continuation
    file_send_line $prompt "yield: $continuation message:" "$@"
    file_wait_for_one_line $continuation 0
}

function some_func() {
    prompt=$1; shift
    yield $prompt "hello"
    yield $prompt "hello2"
    echo "bye"
}

yield_re='yield: (.*) message: (.*)'
return_re='return: (.*)'
prompt=$(make_prompt)
response=$(run $prompt some_func)
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
