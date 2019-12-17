provider "aws" {
    region = "eu-north-1"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}


# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  description = "Separate SG for ELB"
  vpc_id      = aws_vpc.default.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gcapp" {
    description = "SG for web servers"
    vpc_id      = aws_vpc.default.id

    # ssh access from anywhere
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # http access from the VPC
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # app node access to the chef
    egress {
        from_port   = 8889
        to_port     = 8889
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # apt uses port 80
    egress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    # internet on 443
    egress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_elb" "web" {
  name = "gcdemo"

  subnets         = [ "${aws_subnet.default.id}" ]
  security_groups = [ "${aws_security_group.elb.id}" ]
  instances       = aws_instance.gcapp.*.id

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:80/health"
    interval            = 10
  }
}

resource "aws_instance" "gcapp" {
    count             = 3
    #ami               = "ami-005bc7d72deb72a3d"
    ami               = data.aws_ami.ubuntu.id
    instance_type     = "t3.micro"
    key_name          = "martti_gc"
    #security_groups   = ["${aws_security_group.gcapp.name}"] # this stopped working with VPC/ELB?
    vpc_security_group_ids = [ "${aws_security_group.gcapp.id}" ] # needed to use this parameter instead
    subnet_id         = aws_subnet.default.id

    # TODO cannot upgrade the machine here, because this runs into a conflict with chef provisioner? Figure out later?
    user_data = <<-EOF
#!/bin/bash
sudo apt-get update
#sudo DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
EOF

    connection {
        user = "ubuntu"
        private_key = file("~/.ssh/martti_gc.pem")
        host = self.public_ip
    }

    provisioner "chef" {
        attributes_json = <<EOF
        {
            "gcapp": "something",
            "dnsname" : "${self.public_dns}",
            "chef_client": {
                "init_style": "systemd",
                "splay" : 180
            }
        }
        EOF

        environment     = "_default"
        client_options  = ["chef_license 'accept'"]
        run_list        = ["role[webapp]"]
        #node_name       = self.public_dns # inside a local VPC, I guess one doesn't get an automatic DNS name
        node_name       = self.public_ip # but you get a public IP
        #secret_key      = "${file("../encrypted_data_bag_secret")}" # nothing secret in my chef right now
        server_url      = "http://ec2-13-53-194-34.eu-north-1.compute.amazonaws.com:8889"
        recreate_client = true
        user_name       = "chef-bootstrap"
        user_key        = file("~/.ssh/martti_gc.pem")
        #version         = "12.4.1" # in prod env, probably want to pin this
        ssl_verify_mode = ":verify_none"
    }

    # TODO workaround: upgrade machine after bootstrap, because before there was an apt conflict. Not sure why.
    provisioner "remote-exec" {
        script = "bootstrap.bash"
    }
}

# after the terraformation, show the instances created and the LB
output "Instances" {
  value = "${aws_instance.gcapp.*.public_ip}"
}

output "LB" {
  value = "${aws_elb.web.dns_name}"
}