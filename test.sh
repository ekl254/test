#!/bin/bash

red='\e[0;31m'
green='\e[0;32m'
nc='\e[0m'     

base=$(dirname $0)


function tobase(){
    cd $(dirname $0)
}

function ctime(){
    date +"%a %b %d %H:%M:%S %Y"
}



function compile_timer(){
    if [ "$(basename $PWD)"  == "timer" ]
    then
	clang -g -Wall    timer.c   -o timer
    else
	cd timer
	clang -g -Wall    timer.c   -o timer
	cd ..
    fi
}

function clean_timer(){
    if [ "$(basename $PWD)"  == "timer" ]
    then
	rm -f timer
    else
	cd timer
	rm -f timer
	cd ..
    fi
}

function compile_mini-sh(){
    if [ "$(basename $PWD)"  == "mini-sh" ]
    then
	clang -g -Wall -lreadline    mini-sh.c   -o mini-sh
    else
	cd mini-sh
	clang -g -Wall -lreadline   mini-sh.c   -o mini-sh
	cd ..
    fi
}

function clean_mini-sh(){
    if [ "$basename $PWD)"  == "mini-sh" ]
    then
	rm -f mini-sh
    else
	cd mini-sh
	rm -f mini-sh
	cd ..
    fi
}


function compile(){
    compile_timer
    compile_mini-sh
}

function clean(){
   clean_timer
   clean_mini-sh
}



function utest( ){

    if [ "$1" == "$2" ]
    then
	echo -ne "$green pass $nc"
    else
	echo -ne "$red FAIL $nc" 
    fi
    echo -e "\t\t $3"
}

function utest_ne( ){

    if [ "$1" != "$2" ]
    then
	echo -ne "$green pass $nc"
    else
	echo -ne "$red FAIL $nc" 
    fi
    echo -e "\t\t $3"
}

function utest_nz( ){
    if [ ! -z "$1" ]
    then
	echo -ne "$green pass $nc" 
    else
	echo -ne "$red FAIL $nc" 
    fi
    echo -e "\t\t $2"
}

function utest_z( ){
    if [ -z "$1" ]
    then
	echo -ne "$green pass $nc" 
    else
	echo -ne "$red FAIL $nc" 
    fi
    echo -e "\t\t $2"
}


function test_makefile(){
    echo "--- TEST MAKEFILE ---"


    clean_timer
    cd timer
    make 1>/dev/null 2>&1
    res=$(ls timer)
    utest_nz "$res" "timer (make)"

    make clean 1>/dev/null 2>&1
    res=$(ls timer 2>/dev/null)
    utest_z "$res" "timer (make clean)"
    cd ..

    clean_mini-sh
    cd mini-sh
    make 1>/dev/null 2>&1
    res=$(ls mini-sh)
    utest_nz "$res" "mini-sh (make)"


    make clean 1>/dev/null 2>&1
    res=$(ls mini-sh 2>/dev/null)
    utest_z "$res" "mini-sh (make clean)"
    cd ..
    echo
}

function test_timer(){
    echo "--- TEST TIMER ---"

    cd timer
    
    cmd="clang -g -Wall timer.c -o timer 2>&1"
    res=$(eval $cmd)
    utest_z "$res" "compiles without warning or errors ($cmd)"

    cmd="./timer | grep 'Run Time: 0\.0.* (s)'"
    res=$(eval $cmd)
    utest_nz "$res" "prints Run Time with no arguments ($cmd)"

    cmd="./timer ls | grep -v 'Run Time'"
    res=$(eval $cmd)
    expect=$(ls)
    utest "$res" "$expect" "executes ls ($ls)"

    cmd="./timer ls -l | grep -v 'Run Time'"
    res=$(eval $cmd)
    expect=$(ls -l)
    utest "$res" "$expect" "executes ls -l ($cmd)"

    cmd="./timer ls -l -a | grep -v 'Run Time'"
    res=$(eval $cmd)
    expect=$(ls -l -a)
    utest "$res" "$expect" "executes ls -l -a ($cmd)"

    cmd="./timer ls /proc/cpuinfo | head -1"
    res=$(eval $cmd)
    expect="/proc/cpuinfo"
    utest "$res" "$expect" "ls of a file ($cmd)"

    cmd="./timer sleep 2>&1 | grep 'sleep: missing operand'"
    res=$(eval $cmd)
    utest_nz "$res" "Error from sleep on no argument ($cmd)"

    cmd="./timer sleep 1 | grep -o \"[0-9]*\\\\.[0-9]*\" | cut -d \".\" -f 1"
    res=$(eval $cmd)
    expect="1"
    utest "$res" "$expect" "Times properly, 1 second ($cmd)"

    cmd="./timer sleep 2 | grep -o \"[0-9]*\\\\.[0-9]*\" | cut -d \".\" -f 1"
    res=$(eval $cmd)
    expect="2"
    utest "$res" "$expect" "Times properly, 2 seconds ($cmd)"

    cmd="./timer cat /proc/cpuinfo /proc/meminfo /proc/stat | tail -1 | grep -o \"[0-9]*\\\\.[0-9]*\" | cut -d \".\" -f 2"
    res=$(eval $cmd)
    expect="0000"
    utest_ne "$res" "$expect" "Times properly, milisecond ($cmd)"

    cmd="./timer blark -k -o |& grep 'No such file or directory' | sed -e 's/.*No such/No such/'"
    res=$(eval $cmd)
    expect="No such file or directory"
    utest "$res" "$expect" "Exec failure case"
    
    cd ..
    echo
}

function test_mini-sh(){
    echo "--- TEST MINI-SH ---"
    
    cd mini-sh
    cmd="clang -g -Wall -lreadline mini-sh.c -o mini-sh 2>&1"
    res=$(eval $cmd)
    utest_z "$res" "compiles without warning or errors ($cmd)"

    cmd="echo \"ls\" | ./mini-sh | sed \"s/mini-sh ([0-9.]*) #> .*//g\" | sed \"/^$/d\""
    res=$(eval $cmd)

    utest_nz "$res" "executes ls ($cmd)"

    cmd="echo \"BAD\" | ./mini-sh 2>&1 | grep 'No such file or directory'"
    res=$(eval $cmd)
    utest_nz "$res" "$cmd (prints errro on bad command)"

    cmd="echo 'ls' | ./mini-sh 2>&1 | grep -v '^mini-sh'"
    res=$(eval $cmd)
    expect=$(ls)
    utest_nz "expect" "executes ls ($cmd)"

    cmd="echo 'ls -a' | ./mini-sh 2>&1 | grep -v '^mini-sh'"
    res=$(eval $cmd)
    expect=$(ls -a)
    utest_nz "expect" "executes ls -a ($cmd)"

    cmd="echo 'ls -a -l' | ./mini-sh 2>&1 | grep -v '^mini-sh'"
    res=$(eval $cmd)
    expect=$(ls -a)
    utest_nz "expect" "executes ls -a -l ($cmd)"

    cmd="echo 'ls /proc/cpuinfo' | ./mini-sh 2>&1 | grep -v '^mini-sh'"
    res=$(eval $cmd)
    expect=$(ls /proc/cpuinfo)
    utest_nz "expect" "executes ls for a file ($cmd)"


    cmd="echo 'ls /proc/cpuinfo /proc/meminfo /proc/stat' | ./mini-sh 2>&1 | grep -v '^mini-sh'"
    res=$(eval $cmd)
    expect=$(ls /proc/cpuinfo /proc/meminfo /proc/stat)
    utest_nz "expect" "executes ls multiple files ($cmd)"

    cmd="echo -e \"sleep 2\" | ./mini-sh | tail -1 | grep -o \"[0-9.]*\" | cut -d \".\" -f 1"
    res=$(eval $cmd)
    expect="2"
    utest "$res" "$expect" "times 2 seconds ($cmd)"

    cmd="echo -e \"sleep 1\\\\nsleep 2\" | ./mini-sh | tail -2 | grep -o \"mini-sh ([0-9.]*)\" | grep -o \"[0-9.]*\" | cut -d \".\" -f 1 | tr \"\\\\n\" \" \"" 
    res=$(eval $cmd)
    expect="1 2 "
    utest "$res" "$expect" "times two commands ($cmd)"

    echo
}


if [ ! -z $1 ]
then
    cd $1
else
    cd $(dirname $0)
fi

clean
compile

echo

test_makefile
test_timer
test_mini-sh

