#!/bin/bash

read -p "Hey, good morning! What's your name?  " $username

#path of external script
SCRIPT2="/home/citizen/2_digits_test.sh"
#execute it
. "$SCRIPT2"
#back to our wrapper script
echo "well, OK! that worked out very nicely"
