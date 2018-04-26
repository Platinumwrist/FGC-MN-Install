#!/bin/bash

clear
echo "This script will refresh your masternode."
read -p "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

USER=`ps u $(pgrep fantasygoldd) | grep fantasygoldd | cut -d " " -f 1`
USERHOME=`eval echo "~$USER"`

if [ -e /etc/systemd/system/fantasygoldd.service ]; then
  systemctl stop fantasygoldd
else
  su -c "fantasygold-cli stop" $FGCUSER
fi

echo "Refreshing node, please wait."

sleep 5

rm -rf $USERHOME/.fantasygold/blocks
rm -rf $USERHOME/.fantasygold/database
rm -rf $USERHOME/.fantasygold/chainstate
rm -rf $USERHOME/.fantasygold/peers.dat

cp $USERHOME/.fantasygold/fantasygold.conf $USERHOME/.fantasygold/fantasygold.conf.backup
sed -i '/^addnode/d' $USERHOME/.fantasygold/fantasygold.conf

if [ -e /etc/systemd/system/fantasygoldd.service ]; then
  sudo systemctl start fantasygoldd
else
  su -c "fantasygoldd -daemon" $USER
fi

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window." && echo ""

until su -c "fantasygold-cli startmasternode local false 2>/dev/null | grep 'successfully started' > /dev/null" $USER; do
  for (( i=0; i<${#CHARS}; i++ )); do
    sleep 2
    echo -en "${CHARS:$i:1}" "\r"
  done
done

sleep 1
su -c "/usr/local/bin/fantasygold-cli startmasternode local false" $USER
sleep 1
clear
su -c "/usr/local/bin/fantasygold-cli masternode status" $USER
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""
