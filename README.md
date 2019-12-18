# AWS EC2 + Terraform + Chef
Trying out AWS features with Terraform and Chef.

Three EC2 instances are configured to run Nginx with one HTTP basic authenticated web page. Load balancer routes traffic to those three "application" instances. Application can have changes "released" via the Chef "gcapp" cookbook.


## Goal

Create a Hello World static web page protected with basic authentication and running on NGINX. Configuration of Infrastructure and application must be FULLY script based / automated - execute script will setup everything (setup infra, build, test, package and deploy code). Once the web page is running, deploy a change to the application to replace Hello World message with Hello Mars.


## Setup

Prerequisites
* AWS account to create EC2 artifacts
* Terraform (v0.12+) installed
* knife installed (gem install chef)
* AWS CLI installed (apt install awscli or https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html)
* credentials defined in the ~/.aws/credentials file. It is also used by Terraform.

Create ssh key to access instances and also exploited by chef-zero setup.
```
aws ec2 create-key-pair --key-name tf_gc --query 'KeyMaterial' --output text > ~/.ssh/tf_gc.pem
chmod 400 ~/.ssh/tf_gc.pem
```

Then run setup script
```
bash setup.sh
```
After the chef-zero server has been created, you need to copy the DNS name to TWO places
```
terraform_aws_demo/tf-gcapp.tf: server_url = "http://ec2-13-53-140-37.eu-north-1.compute.amazonaws.com:8889"
~/.chef/knife.rb: chef_server_url 'http://ec2-13-53-140-37.eu-north-1.compute.amazonaws.com:8889'
```

Note the public DNS name and reference it on your local ~/.chef/knife.rb with port 8889 - that's where chef-zero lives. Reference whatever RSA key file as your client_key. Chef-client needs it to function, but chef-zero doesn't check it.

Make sure your cookbook_path references the chefrepo/cookbooks directory.

~/.chef/knife.rb
```
ssl_verify_mode :verify_none
node_name 'whatever'
chef_server_url 'http://ec2-13-53-140-37.eu-north-1.compute.amazonaws.com:8889'
client_key '~/.ssh/tf_gc.pem'
cookbook_path ["~/dev/terraform_aws_demo/chefrepo/cookbooks"]
```

In the end of your run you should get a list of nodes bootstrapped and the LB DNS name. You might need to wait couple of minutes for the DNS configuration to propagate. 

```
Outputs:

Instances = [
  "13.53.136.60",
  "13.53.169.255",
  "13.53.192.8",
]
LB = gcdemo-1754880613.eu-north-1.elb.amazonaws.com
```

Then just visit the LB DNS on port 80 http://gcdemo-1754880613.eu-north-1.elb.amazonaws.com/
```
User gc
Password gcdemo
```

If you refresh the page, you should see the Hello World page with IP rotating though all three nodes.


## Teardown

Just run the script to destroy the webapp and chef-zero instances.
```
bash destroy.sh
```