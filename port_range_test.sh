#! /bin/bash

#make sure an input variable is in the accepted port range
if [ "$1" -ge 1024 ] && [ "$1" -le 65535 ]
then
echo "Your port " $1 " passes the test of being between 1025 and 65535"
else
echo "sorry your port is out of range"
fi
