#!/bin/bash

IPC_FILE=~/.servinp

rm -rf $IPC_FILE
touch $IPC_FILE
tail -f $IPC_FILE 2> /dev/null | ./job_commands.sh &
