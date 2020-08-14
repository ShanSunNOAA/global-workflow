#!/bin/bash

while read line; do
   echo "" &>~/.output.log
   echo "[HOST] Executing command: $line" &>~/.output.log
   bash -c "$line" &>~/.output.log
   cat /dev/null >~/.servinp
done
