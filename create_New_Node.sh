#!/bin/bash

#check that Jormungandr and JCLI have been installed
CMD1=jcli
CMD2=jormungandr
if command -v $CMD1 && command -v $CMD2 > /dev/null 2>&1
  then 
    echo $CMD1" and "$CMD2" both found"
  else 
    echo $CMD1" or "$CMD2" not found. Please install both before continuing."
    exit
fi

#check if the script was given an argument
if [ -z $1 ]
then
  #script wasn't passed an input argument, try again
  echo "Give a number or letter to assign for the new Node, eg Node04 or NodeD"
  echo "RECOMMENDED to use a two digit number for NODE_ID (eg 88) as it can be used for your PORT configuration in your new node-config file"
else
  #I suck at indenting, so this looks like garbage, sorry
    if [ -d ~/node$1 ]
    then
        echo "Ooops. Try again because ~/node"$1" already exists. Choose another number or letter for your new NODE_ID"
    else
        #get your server's public IP address and current username
        PUBLC_ADDRESS=dig +short myip.opendns.com @resolver1.opendns.com)
        echo "creating node for user: "$USER" on IP address: "$PUBLC_ADDRESS
        #set the GENESIS_BLOCK_HASH variable for ITNv1 if not already set
        [[ $GENESIS_BLOCK_HASH ]] && echo $GENESIS_BLOCK_HASH || GENESIS_BLOCK_HASH =8e4d2a343f3dcf9330ad9035b3e8d168e6728904262f2c434a4f8f934ec7b676 && echo "using Genesis Block Hash for ITN v1: " $GENESIS_BLOCK_HASH; 
        # ok let's make the directories for your new node 
        echo "Creating directory and files for node"$1" now..."
        mkdir -v  ~/node$1
        mkdir -v ~/node$1/storage$1
        [ ! -d ~/storage/ ] || mkdir -v ~/storage && echo "will take a bit longer to bootstrap without a recent copy of the blockchain blocks.sqlite"
        [ -f ~/storage/blocks.sqllite ] && cp -a -v ~/storage/. ~/storage$1/ || echo "we didn't find a copy of the blockchain db, so the node will build one later" 
        mkdir -v ~/node$1/files
        echo "Creating log file for node"$1
        touch ~/logs/node$1.out
        #done making new directories and files
        #check for node-config-GENERIC-INFILE.yaml in user home directory
            if [ -f ~/node-config-GENERIC-INFILE.yaml ]
            then
                 cp -v ~/node-config-GENERIC-INFILE.yaml ~/node$1/files/
                 #check for 2 or 3 digit NODE_ID or not
                 if [[ $1 =~ ^[0-9]{2,3}$ ]] && ((number=10#$1))
                 then
                       echo "Modifying your node-config"$1".yaml file with your two digit NODE_ID: "$1
                       sed 's/<PUBLC_ADDRESS>/'$PUBLC_ADDRESS'/g' <~/node$1/files/node-config-GENERIC-INFILE.yaml >~/node$1/files/node-config$1.yaml
                       sed 's/<USERNAME>/'$USER'/g' <~/node$1/files/node-config-GENERIC-INFILE.yaml >~/node$1/files/node-config$1.yaml
                       sed 's/<NODE_ID>/'$1'/g' <~/node$1/files/node-config-GENERIC-INFILE.yaml >~/node$1/files/node-config$1.yaml
                       echo "Confirm deletion of temporary generic node-config from files directory"
                       rm -i -v ~/node$1/files/node-config-GENERIC-INFILE.yaml
                       echo "OK, let's update your firewall. You'll need to enter the PASSWORD for the current USER"
                       echo "This is required for the node to reach peers in the outside world"
                       echo "We're going to open port: 31"$1 "to ALLOW IN tcp traffic from Anywhere."
                       sudo ufw --force enable
                       sudo ufw allow 31$1
                       sudo ufw reload
                       # that's pretty cool, but this is where it all starts...
                       echo "Starting Jormungandr PASSIVE node: node"$1" on LISTEN port 31"$1" and REST port 41"$1
                       nohup jormungandr --genesis-block-hash ${GENESIS_BLOCK_HASH} --config ~/node$1/files/node-config$1.yaml > ~/node$1/files/nohup$1.out &
                       echo "......waiting 10 seconds for node to start....."
                       sleep 10
                       echo "$(jcli rest v0 node stats get -h http://127.0.0.1:41"$1"/api)"
                       #
                       #Taken directly from IOHK guide on registering a stake pool
                       # https://github.com/cardano-foundation/incentivized-testnet-stakepool-registry/wiki/How-to-register-your-stake-pool-on-the-chain
                       # Step 2 : Get your reward credentials 
                       echo "Generating wallet address and keys for your pledge account now..."
                       jcli key generate --type ed25519 | tee ~/node$1/files/owner$1.prv | jcli key to-public > ~/node$1/files/owner$1.pub
                       echo "Generating your owner.addr (pledge address) file..."
                       jcli address account --testing --prefix addr $(cat ~/node$1/files/owner$1.pub) > ~/node$1/files/owner$1.addr
                       # Step 3: Fund your account
                       echo "OK! Time to fund your pledge account with 500.3 tAda!"
                       echo "FUND: use Daedalus or cardano-wallet and send funds to this address: "$(cat ~/node$1/files/owner$1.addr)
                       # Step 4: Generate your pools credentials
                       echo "Let's go ahead and generate your new node's public and private keys"
                       read -p "Do you understand that after we do this, you will need to PROTECT your PRIVATE KEYS by saving them off this server? y/n " keyresponse
                       #TODO: if $keyresponse != "y" then exit fi
                       #[[ $keyresponse != "y" ]] || { echo "Must answer y"; exit 1; }
                       echo "You told me "$keyresponse" so I am trusting you to do that soon."
                       # Step 5: Generate your registration certificate
                       echo "Making your public and private keys now. They will be in your ~/node"$1"/files directory."
                       jcli key generate --type=SumEd25519_12 > ~/node$1/files/kes$1.prv
                       jcli key to-public < ~/node$1/files/kes$1.prv > ~/node$1/files/kes$1.pub
                       jcli key generate --type=Curve25519_2HashDH > ~/node$1/files/vrf$1.prv
                       jcli key to-public < ~/node$1/files/vrf$1.prv > ~/node$1/files/vrf$1.pub
                       #get the inputs for Tax Ratio, Tax Fixed, and Tax Limit (optional)
                        echo "******=========******"
                        echo "Now let's set up your pool's fee structure"
                        echo "Do this carefully, because I'm not checking your math for errors!"
                        #
                        #TAX RATIO set below, also known as tax rate your pool charges delegators
                        echo "========="
                        echo "SET TAX RATIO: the percentage of rewards your pool will deduct from total rewards earned."
                        echo "This MUST be entered in a fraction, eg for 10% enter 1/10, for 1% enter 1/100, for 2.75% enter 275/10000"
                        read -p "What do you want your pool's Tax rate to be? (in fraction form) :" TAX_RATIO
                        echo "You entered a Tax rate of: " 
                        awk -vn=$TAX_RATIO 'BEGIN{print(('$TAX_RATIO')*100)" %"}'
                        #TODO: error check confirmation, for now, just do it
                        #read -p "Is this correct? (y/n)" confirm_TAX_RATIO
                        #
                        #TAX_FIXED set below, also known as flat tax
                        echo "========="
                        echo "SET TAX FIXED: this is a flat fee in Ada that your pool will deduct from total rewards earned."
                        read -p "What is your pool's Fixed Tax fee in Ada? " TAX_FIXED
                        echo "shown in lovelaces: "
                        awk -vn=$TAX_FIXED 'BEGIN{print(('$TAX_FIXED')*1000000)" Lovelaces"}'
                        #TODO: error check confirmation, for now, just do it
                        #read -p "Is this correct? y/n" confirm_TAX_FIXED
                        #
                        #TAX_LIMIT set below, the maximum amount of fees your pool will take from rewards
                        echo "========="
                        echo "SET TAX LIMIT: this is a MAXIMUM or CAP of rewards in Ada that your pool will receive from total rewards earned."
                        read -p "What is your pool's Tax Limit cap in Ada? " TAX_LIMIT
                        echo "shown in lovelaces: "
                        awk -vn=$TAX_LIMIT 'BEGIN{print(('$TAX_LIMIT')*1000000)" Lovelaces"}'
                        #TODO: error check confirmation, for now, just do it
                        #read -p "Is this correct? y/n" confirm_TAX_LIMIT
                        #
                        #TODO: concatenate the jcli command with the input variables from above
                        # Step 5.5 Generate your pool registration certificate
                        echo "Creating your stake pool registration certificate in ~/node"$1"/files directory"
                        echo "$(jcli certificate new stake-pool-registration --kes-key $(cat ~/node"$1"/files/kes"$1".pub) --vrf-key $(cat ~/node"$1"/files/vrf"$1".pub) --owner $(cat ~/node"$1"/files/owner"$1".addr) --management-threshold 1 --tax-limit "$TAX_LIMIT"  --tax-ratio "$TAX_RATIO" --tax-fixed "$TAX_FIXED" --start-validity 0 > ~/node"$1"/files/stake-pool-registration"$1".cert)"
                       echo "Whew. That was more work than I expected."
                       read -p "Remind me of your name please?  " username
                       echo "It's been fun "$username"! Let's do this again sometime soon!"
                       echo "OK! All done for now...and"
                       echo "Hey, "$username", remember to send 500.3 tAda to your pledge address and PROTECT YOUR KEYS!"
                       sleep 3
                 else
                       #the given NODE_ID is something other than 2 or 3 digits
                       echo "You chose to name your Node something other than 2 or 3 digits, against my advice. Anyways...."
                       sleep 5
                       #TODO: we'll fix this later if the node is named something other than 2 or 3 digits

                  fi
            else
              echo  "ATTENTION: you must put a copy of node-config-GENERIC-INFILE.yaml in your home directory"
            fi
    fi
# closes the opening check for an argument
fi
