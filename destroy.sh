#!/usr/bin/env bash
echo
echo "##################### Clean up the environment? #####################"
echo
read -p 'Type "yes" to continue: ' uservar

if [ $uservar != "yes" ] ; then
    exit -1
fi

echo
echo "#### Destroying webapp in AWS ####"
echo
cd tf-gcapp/
terraform destroy --auto-approve

echo
echo "#### Destroying Chef-Zero ####"
echo
cd ../tf-chef-zero/
terraform destroy --auto-approve