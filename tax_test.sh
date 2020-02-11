#!/bin/bash

#get the inputs for Tax Ratio, Tax Fixed, and Tax Limit (optional)
echo "Now let's set up your pool's fee structure"
echo "Do this carefully, because I'm not checking your math for errors!"
#
#TAX RATIO set below, also known as tax rate your pool charges delegators
echo "========="
echo "SET TAX RATIO: the percentage of rewards your pool will deduct from total rewards earned."
echo "This MUST be entered in a fraction, eg for 10% enter 1/10, for 1% enter 1/100, for 2.75% enter 275/10000"
read -p "What do you want your pool's Tax rate to be? (in fraction form) :" TAX_RATIO
TAX_RATIO=$TAX_RATIO
echo $TAX_RATIO
echo "You entered a Tax rate of: "
awk -vn=$TAX_RATIO 'BEGIN{print(($TAX_RATIO)*100)" %"}'
#TODO: error check confirmation, for now, just do it
#read -p "Is this correct? (y/n)" confirm_TAX_RATIO
echo "Well, I hope it's right because I don't have error handling for your mistakes"
#
#TAX_FIXED set below, also known as flat tax
echo "========="
echo "SET TAX FIXED: this is a flat fee in Ada that your pool will deduct from total rewards earned."
read -p "What is your pool's Fixed Tax fee in Ada? " TAX_FIXED
TAX_FIXED=$TAX_FIXED
echo "shown in lovelaces: "
awk -vn=$TAX_FIXED 'BEGIN{print(($TAX_FIXED)*1000000)" Lovelaces"}'
#TODO: error check confirmation, for now, just do it
#read -p "Is this correct? y/n" confirm_TAX_FIXED
#
#TAX_LIMIT set below, the maximum amount of fees your pool will take from rewards
echo "========="
echo "SET TAX LIMIT: this is a MAXIMUM or CAP of rewards in Ada that your pool will receive from total rewards earned."
read -p "What is your pool's Tax Limit cap in Ada? " TAX_LIMIT
TAX_LIMIT=$TAX_LIMIT
echo "shown in lovelaces: "
awk -vn=$TAX_LIMIT 'BEGIN{print(($TAX_LIMIT)*1000000)" Lovelaces"}'
#TODO: error check confirmation, for now, just do it
#read -p "Is this correct? y/n" confirm_TAX_LIMIT

echo "jcli-test certificate new stake-pool-registration \"
#echo "    --kes-key $(cat ~/node$1/files/kes$1.pub) \"
#echo "    --vrf-key $(cat ~/node$1/files/vrf$1.pub) \"
#echo "    --owner $(cat ~/node$1/files/owner$1.addr) \"
echo "    --management-threshold 1 \"
echo "    --tax-limit $TAX_LIMIT \"
echo "    --tax-ratio $TAX_RATIO \"
echo "    --tax-fixed $TAX_FIXED \"
echo "    --start-validity 0 \"
echo "    > stake-pool-registration.cert"

echo "cool. we made it to the eof."
