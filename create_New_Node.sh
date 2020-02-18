#!/bin/bash

# let' set some variables, even we don't get to use them all
CMD1=jcli
CMD2=jormungandr
USERNAME=$USER
PUBLIC_ADDRESS=$(dig +short myip.opendns.com @resolver1.opendns.com)
# set the GENESIS_BLOCK_HASH variable for ITNv1 if not already set
[[ $GENESIS_BLOCK_HASH ]] || GENESIS_BLOCK_HASH="8e4d2a343f3dcf9330ad9035b3e8d168e6728904262f2c434a4f8f934ec7b676"
# check that Jormungandr and JCLI are installed, and if a node is already running use it for something!
if command -v $CMD1 && command -v $CMD2 > /dev/null 2>&1
  then 
    echo $CMD1" and "$CMD2" installed already!"
#    jsettingsf="/tmp/.jorm_settings.tmp"
#    read -p "What REST PORT is an active node using? [4 or 5 digits >= 1025, please] " JormPORT
#    if [[ $JormPORT =~ ^[0-9]{4,5}$ ]] && ($JormPORT -ge 1024); then 
#      jcli rest v0 settings get --output-format json -h http://127.0.0.1:$JormPORT > $jsettingsf
#      rc=$?
#      if [ $rc -ne 0 ]; then
#        # do something useful here with the json output
#        else
#        "Atleast one node needs to be up and responding before starting this script!"
#        exit 1
#      fi
#    fi
  else 
    echo $CMD1" and/or "$CMD2" not found. Please install both before continuing."
    exit 1
fi

#check if the script was given an argument
if [ -z $1 ]
then
  #script wasn't passed an input argument, try again
  echo "Choose an alphanumeric ID for the new Node, eg 04 or D or ALICE"
  echo "We RECOMMEND a 2 or 3 digit number for NODE_ID [eg 88 or 456] which can also be used for your PORTS"
  exit 1
fi

# check if the new Node ID has already been used
if [ -d ~/node$1 ] ; then echo "Ooops. Try another node ID. ~/node"$1" already exists." && exit 1 ; fi

# make the directories and files for your new node 
    echo "Creating directory and files for node"$1" now..."
    mkdir -v  ~/node$1
    mkdir -v ~/node$1/storage$1
    # TODO: OR NOT...make a publicly available copy of the blockchain blocks.sqlite file via https
    # use a watch n 60 cp ~/storage ~/path/to/publicly/available/blocks.sqlite ?
    #[ -d ~/storage ] || mkdir -v ~/storage && echo "will take a bit longer to bootstrap without a recent copy of the blockchain blocks.sqlite"
    [ -f ~/storage/blocks.sqllite ] && cp -a -v ~/storage/. ~/storage$1/ || echo "we didn't find a copy of the blockchain db, so the node will build one later" 
    mkdir -v ~/node$1/files
    echo "Creating log file for node"$1
    if [ ! -d ~/logs ] ; then mkdir -v ~/logs; fi
    touch ~/logs/node$1.out
    #done making new directories and files
    
  # check for node-config-GENERIC-INFILE.yaml in user home directory and copy to new node dir
    if [ ! -f ~/node-config-GENERIC-INFILE.yaml ] ; then cd && wget -nc https://raw.githubusercontent.com/citizencosmos/Cardano/master/node-config-GENERIC-INFILE.yaml; fi
  # copy node-config-GENERIC to new node directory
    cp -v ~/node-config-GENERIC-INFILE.yaml ~/node$1/files/
    
  # check for 2 or 3 digit NODE_ID
if [[ $1 =~ ^[0-9]{2,3}$ ]] && ((number=10#$1))
then  #
        echo "Modifying your node-config"$1".yaml file with your two digit NODE_ID: "$1
        sed 's/<PUBLC_ADDRESS>/'$PUBLC_ADDRESS'/g' ~/node$1/files/node-config-GENERIC-INFILE.yaml
        sed 's/<USERNAME>/'$USER'/g' ~/node$1/files/node-config-GENERIC-INFILE.yaml
        sed 's/<NODE_ID>/'$1'/g' <~/node$1/files/node-config-GENERIC-INFILE.yaml >~/node$1/files/node-config$1.yaml
        #leave peers section commented out if user indicates there is already an instance of jormungandr running
        read -p "Do you already have an active Jormungandr node currently running on this server? [Y/n] " existsLiveJorm
        if [ ! $existsLiveJorm == "Y" ]; then sed '20,48{s/#PEER#/''/g}' ~/node$1/files/node-config$1.yaml; fi
        #  delete temporary generic node-config from files directory"
        rm ~/node$1/files/node-config-GENERIC-INFILE.yaml
        
        # update Uncomplicated Firewall [UFW] with rules for new ports
        echo "OK, let's update your firewall. You'll need to enter the PASSWORD for the current USER"
        # echo "This is required for the node to reach peers in the outside world"
        echo "We're going to open port: 31"$1 "to ALLOW IN tcp traffic from Anywhere."
        sudo ufw --force enable
        sudo ufw allow 31$1
        sudo ufw reload
        
        # that's pretty cool, but this is where it all starts... spin up a Jormungandr passive node!
        echo "Starting Jormungandr PASSIVE node: node"$1" on LISTEN port 31"$1" and REST port 41"$1
        nohup jormungandr --genesis-block-hash ${GENESIS_BLOCK_HASH} --config ~/node$1/files/node-config$1.yaml > ~/node$1/files/nohup$1.out &
        echo "......waiting 20 seconds for node to start....."
        sleep 20
        # get and echo the current status of the new passive node
        echo "$(jcli rest v0 node stats get -h http://127.0.0.1:41"$1"/api)"
        
        # Do you want to make this node a Leader node? If Yes we need to do the do the stuff below
        
        # Below is taken directly from IOHK guide on registering a stake pool
        # https://github.com/cardano-foundation/incentivized-testnet-stakepool-registry/wiki/How-to-register-your-stake-pool-on-the-chain
        
        # Step 2 : Get your reward credentials 
        echo "Generating wallet address and keys for your pledge account now..."
        jcli key generate --type ed25519 | tee ~/node$1/files/owner$1.prv | jcli key to-public > ~/node$1/files/owner$1.pub
        echo "Generating your owner.addr (pledge address) file..."
        jcli address account --testing --prefix addr $(cat ~/node$1/files/owner$1.pub) > ~/node$1/files/owner$1.addr
        
        # Step 3: Fund your account
        echo "OK! Time to fund your pledge account with 500.3 tAda! I can't do this for you."
        echo "FUND: use Daedalus or cardano-wallet and send funds to this address: "$(cat ~/node$1/files/owner$1.addr)
        
        # Step 4: Generate your pools credentials
        echo "Let's go ahead and generate your new node's public and private keys"
        echo "You WILL need to PROTECT all your PRIVATE KEYS by saving them off this server!"
        keyProtect=n
        while [ ! $keyProtect == "Y" ]
            do read -p "Confirm that you *WILL* protect your private keys [Y/n]: " keyProtect
            done
        echo "OK, I believe you."
        
        # Step 5: Generate your registration certificate
        echo "Making your public and private keys now. They will be in your ~/node"$1"/files directory."
        jcli key generate --type=SumEd25519_12 > ~/node$1/files/kes$1.prv
        jcli key to-public < ~/node$1/files/kes$1.prv > ~/node$1/files/kes$1.pub
        jcli key generate --type=Curve25519_2HashDH > ~/node$1/files/vrf$1.prv
        jcli key to-public < ~/node$1/files/vrf$1.prv > ~/node$1/files/vrf$1.pub
        #
        # get the inputs for Tax Ratio, Tax Fixed, and Tax Limit (optional)
        #
        echo "******************===============================******************"
        echo "Now let's set up your pool's fee structure"
        echo "Do this carefully, because I'm not checking your math for errors!"
        #
        # TAX RATIO set below, also known as tax rate your pool charges delegators
        #
        echo "=========  SET TAX_FIXED  ========="
        echo "The Fixed Tax is the flat fee your pool will take off the top of total rewards earned."
        echo "IOHK definition: this is the fixed cut the stake pool will take from the total reward due to the stake pool;"
        TAX_FIXED_ADA=0
        Lovelaces=1000000
        confirm_TAX_FIXED="n"
        while [ ! $confirm_TAX_FIXED == "Y" ]
          do
            read -p "What is your pool's Fixed Flat Fee? [in Ada, use decimals if you like]:" TAX_FIXED_ADA
            TAX_FIXED=0
            echo "You entered a TAX_FIXED flat fee of: " $TAX_FIXED_ADA " Ada which is :"
            TAX_FIXED=$(awk -v taxfixed=$TAX_FIXED_ADA 'BEGIN{print(('$TAX_FIXED_ADA' * '$Lovelaces'))}')
            echo $TAX_FIXED " when shown in Lovelaces"
            # confirm TAX_FIXED fee, user must answer Y
            read -p "Is this correct? [Y/n]" confirm_TAX_FIXED
          done
        echo "OK, your TAX_FIXED flat fee is: " $TAX_FIXED " Lovelaces"
        #
        # TAX RATIO set below, also known as tax rate your pool charges delegators
        echo "=========  SET TAX_RATIO  ========="
        echo "The Tax Ratio is the percentage of rewards your pool will deduct from total rewards earned, *after* the FIXED Tax has been deducted."
        echo "IOHK definition: this is the percentage of the remaining value that will be taken from the total due"
        echo "Enter in fraction form [eg for 10% enter 1/10, for 1% enter 1/100, for 2.75% enter 275/10000]"
        TAX_RATIO=0
        PCT=100
        confirm_TAX_RATIO="n"
        while [ ! $confirm_TAX_RATIO == "Y" ]
          do
            read -p "What is your pool's Tax Ratio? [in fraction form]:" TAX_RATIO_INPUT
            TAX_RATIO=0
            TAX_RATIO=$(awk -v taxrate=$TAX_RATIO_INPUT 'BEGIN{print(('$TAX_RATIO_INPUT' * '$PCT'))" %"}')  #convert and display as a percentage
            echo "You entered a Tax rate of: "$TAX_RATIO
            read -p "Is this correct? [Y/n]" confirm_TAX_RATIO
          done
        echo "OK, your TAX RATIO is: "$TAX_RATIO
        # TAX_LIMIT set below, the maximum amount of fees your pool will take from rewards
        echo "=========  SET TAX_LIMIT  ========="
        echo "The Tax Limit is the cap or maximum of all fees your pool will take from total rewards earned."
        echo "IOHK definition: a value that can be set to limit the pool's Tax."
        TAX_FIXED_LIMIT=0
        confirm_TAX_LIMIT="n"
        while [ ! $confirm_TAX_LIMIT == "Y" ]
          do
            read -p "What is your pool's Tax Limit or cap? [in Ada, use decimals if you like]:" TAX_LIMIT_ADA
            TAX_LIMIT=0
            echo "You entered a TAX_LIMIT cap of: " $TAX_LIMIT_ADA " Ada which is :"
            TAX_LIMIT=$(awk -v taxlimit=$TAX_LIMIT_ADA 'BEGIN{print(('$TAX_LIMIT_ADA' * '$Lovelaces'))}')
            echo $TAX_FIXED " when shown in Lovelaces"
            # confirm TAX_LIMIT fee, user must answer Y
            read -p "Is this correct? [Y/n]" confirm_TAX_FIXED
          done
        echo "OK, your TAX_LIMIT or capped fee is: " $TAX_FIXED " Lovelaces"
        #
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
        echo "Bye Bye for now"
        exit 1
        #TODO: we'll add functionality this later if the node is named something other than 2 or 3 digits
fi

