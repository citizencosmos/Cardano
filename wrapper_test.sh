#!/bin/bash

read -p "Hey, good morning! What's your name?  " $username
echo "Let's gather some preliminary information for the second script..."
read -p "What's your favorite 2 or 3 digit number?  " $1

#path of external script, use full path ~/ didn't seem to work
SCRIPT2="/home/citizen/2_digits_test.sh"

#execute the external script
. "$SCRIPT2"

#back to our wrapper script
echo " OK, did the number turn out like you hoped it would "
#did it reset the variable $username to your second response, gathered by the external script?
echo "well, OK! that almost worked out very nicely " $username
