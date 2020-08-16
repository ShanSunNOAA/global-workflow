#!/bin/bash

IPC_FILE=~/.servinp
OUT_FILE=~/.output.log
WDIR="$( dirname "${BASH_SOURCE[0]}" )"

rm -rf $IPC_FILE $OUT_FILE
touch $IPC_FILE

#read and execute one command
tail -f $IPC_FILE 2>/dev/null | {
  read line
  echo "" &>$OUT_FILE
  echo "[HOST] Executing command: $line" &>$OUT_FILE
  bash -c "$line" &>$OUT_FILE
  cat /dev/null >$IPC_FILE
} &
