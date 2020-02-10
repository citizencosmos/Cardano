#!/bin/bash
#check if the script was given an argument
if [ -z $1 ]
then
#script wasn't passed an input argument, try again
echo "Give a number or letter to assign for the new Node, eg Node4 or NodeD"
echo "RECOMMENDED to use a two digit number for NODE_ID (eg 88) as it can be used for your PORT configuration in your new node-config file"
else
#I suck at indenting, so this looks like garbage, sorry
  if [ -d ~/node$1 ]
  then
      echo "Ooops. Try again because ~/node"$1" already exists. Choose another number or letter for your new NODE_ID"
  else
      echo "Creating directory and files for node"$1" now..."
      mkdir -v  ~/node$1
      mkdir -v ~/storage$1
      cp -a -v ~/storage2/. ~/storage$1/
      mkdir -v ~/node$1/files
      echo "Creating log file for node"$1
      touch ~/logs/node$1.out
      #done making new directories and files
      #check for node-config-GENERIC-INFILE.yaml in user home directory
          if [ -f ~/node-config-GENERIC-INFILE.yaml ]
          then
               cp -v ~/node-config-GENERIC-INFILE.yaml ~/node$1/files/
               #check for 2 digit NODE_ID or not
               if [[ $1 =~ ^[0-9]{2,3}$ ]] && ((number=10#$1))
               then
                     echo "Modifying your node-config"$1".yaml file with your two digit NODE_ID: "$1
                     sed 's/<NODE_ID>/'$1'/g' <~/node$1/files/node-config-GENERIC-INFILE.yaml >~/node$1/files/node-config$1.yaml
                     echo "Confirm deletion of temporary generic node-config from files directory"
                     rm -i -v ~/node$1/files/node-config-GENERIC-INFILE.yaml
                     echo "OK, let's update your firewall. You'll need to enter the PASSWORD for the current USER"
                     echo "This is required for the node to reach peers in the outside world"
                     echo "We're going to open port: 31"$1 "to ALLOW IN tcp traffic from Anywhere."
                     sudo ufw --force enable
                     sudo ufw allow 31$1
                     sudo ufw reload
                     echo
                     echo "Starting Jormungandr PASSIVE node: node"$1" on LISTEN port 31"$1" and REST port 41"$1
                     nohup jormungandr --genesis-block-hash ${GENESIS_BLOCK_HASH} --config ~/node$1/files/node-config$1.yaml > ~/node$1/files/nohup$1.out &
                     echo "......waiting 10 seconds for node to start....."
                     sleep 10
                     echo "$(jcli rest v0 node stats get -h http://127.0.0.1:41"$1"/api)"
                     echo "Generating wallet address and keys for your pledge account now..."
                     jcli key generate --type ed25519 | tee ~/node$1/files/owner$1.prv | jcli key to-public > ~/node$1/files/owner$1.pub
                     echo "Generating your owner.addr (pledge address) file..."
                     jcli address account --testing --prefix addr $(cat ~/node$1/files/owner$1.pub) > ~/node$1/files/owner$1.addr
                     echo "OK! Time to fund your pledge account with 500.3 tAda!"
                     echo "FUND: use Daedalus or cardano-wallet and send funds to this address: "$(cat ~/node$1/files/owner$1.addr)
                     echo "Let's go ahead and generate your new node's public and private keys"
                     read -p "Do you understand that after we do this, you will need to PROTECT your PRIVATE KEYS by saving them off this server?" response
                     echo "You told me "$response" so I am trusting you to do that soon."
                     jcli key generate --type=SumEd25519_12 > ~/node$1/files/kes$1.prv
                     jcli key to-public < ~/node$1/files/kes$1.prv > ~/node$1/files/kes$1.pub
                     jcli key generate --type=Curve25519_2HashDH > ~/node$1/files/vrf$1.prv
                     jcli key to-public < ~/node$1/files/vrf$1.prv > ~/node$1/files/vrf$1.pub
                     read -p "Remind me of your name please?  " username
                     echo "It's been fun "$username"! Let's do this again sometime soon!"
                     echo "OK! All done for now...and"
                     echo "Hey, "$username", remember to send 500.3 tAda to your pledge address and PROTECT YOUR KEYS!"
                     sleep 3
               else
                     #the given NODE_ID is something other than 2 or 3 digits
                     echo "ATTENTION: you *must* edit the PORTS in ~/node"$1"/files/node-config"$1".yaml"
                     echo "Replace the placeholder <NODE_ID> with your preferred 2 digit number (eg 99) or assign your own PORTS"
                     #edit storage path in node-config by replacing <NODE_ID> with the argument
                     sed 's/storage<NODE_ID>/storage'$1'/g' <~/node$1/files/node-config-GENERIC-INFILE.yaml >~/node$1/files/node-config$1.yaml
                     echo "Confirm deletion of generic node-config from files directory"
                     rm -i -v ~/node$1/files/node-config-GENERIC-INFILE.yaml
                fi
          else
            echo  "ATTENTION: you must put a copy of node-config-GENERIC-INFILE.yaml in your home directory (eg ~/ or /home/<username>/)"
          fi
  fi
# closes the opening check for an argument
fi
