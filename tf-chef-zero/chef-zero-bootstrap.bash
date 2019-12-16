#!/bin/bash
sudo touch /var/log/terraform_bootstrap.log
sudo chown root:adm /var/log/terraform_bootstrap.log
sudo chmod 664 /var/log/terraform_bootstrap.log
sudo apt-get update >> /var/log/terraform_bootstrap.log
sudo DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade >> /var/log/terraform_bootstrap.log
sudo apt-get update >> /var/log/terraform_bootstrap.log
sudo apt-get install chef-zero -y >> /var/log/terraform_bootstrap.log
sudo chef-zero -d -H 0.0.0.0 --log-file /var/log/chef-zero.log >> /var/log/terraform_bootstrap.log