# AWS EC2 + Terraform + Chef
Trying out AWS features with Terraform and Chef.

Three EC2 instances are configured to run Nginx with one HTTP basic authenticated web page. Load balancer routes traffic to those three "application" instances. Application can have changes "released" via the Chef "gcapp" cookbook.


## Goal

Create a Hello World static web page protected with basic authentication and running on NGINX. Configuration of Infrastructure and application must be FULLY script based / automated - execute script will setup everything (setup infra, build, test, package and deploy code). Once the web page is running, deploy a change to the application to replace Hello World message with Hello Mars.


## Setup

Have terraform (v0.12+) installed. Have knife installed.

Have AWS credentials in the ~/.aws/credentials file. It is also used by Terraform.

### chef-zero
Setup the fake Chef server by chef-zero
```
cd tf-chef-zero
terraform plan
terraform apply --auto-approve
```

Note the public DNS name and reference it on your local ~/.chef/knife.rb with port 8889 - that's where chef-zero lives. Reference whatever RSA key file as your client_key. Chef-client needs it to function, but chef-zero doesn't check it.

### Upload Chef artefacts

Make sure your cookbook_path references the chefrepo/cookbooks directory.

~/.chef/knife.rb
```
ssl_verify_mode :verify_none
node_name 'whatever'
chef_server_url 'http://ec2-13-53-194-34.eu-north-1.compute.amazonaws.com:8889'
client_key '~/.ssh/martti_gc.pem'
cookbook_path ["~/dev/terraform_aws_demo/chefrepo/cookbooks"]
```

Now you're ready to upload the contents of Chef server - webapp role and cookbooks.
```
cd ../chefrepo
knife upload .
```

### Create the web application cluster

And now you can create the web application on AWS.
```
cd ../tf-gcapp
terraform plan
terraform apply --auto-approve
```

In the end of your run you should get a list of nodes bootstrapped and the LB DNS name. You might need to wait couple of minutes for the DNS configuration to propagate. 

```
Outputs:

Instances = [
  "13.48.67.236",
  "13.48.26.0",
  "13.48.84.243",
]
LB = gcdemo-441074539.eu-north-1.elb.amazonaws.com
```