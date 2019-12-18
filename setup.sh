#!/usr/bin/env bash
echo
echo "##################### Setting up Chef-Zero #####################"
echo
cd tf-chef-zero/
terraform apply --auto-approve

echo
echo "#### TODO: Now copy the Chef server DNS name into your .chef/knife.rb and tf-gcapp/tf-gcapp.tf ####"
echo
read -p 'Type "yes" to continue: ' uservar

if [ $uservar != "yes" ] ; then
    exit -1
fi

echo
echo "#### Uploading Chef artefacts ####"
echo
cd ../chefrepo
knife upload .

echo
echo "#### Create webapp into AWS ####"
echo
cd ../tf-gcapp
terraform apply --auto-approve

cd ..