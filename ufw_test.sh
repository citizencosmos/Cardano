#!/bin/bash
#open ports for listen_address and public_address
sudo ufw --force enable
sudo ufw allow 31$1
sudo ufw reload
