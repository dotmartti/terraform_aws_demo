provider "aws" {
    region = "eu-north-1"
}

resource "aws_security_group" "gcapp_sg" {
    name        = "gcapp_sg"
    description = "SG for web servers"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 8889
        to_port     = 8889
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "gcapp" {
    count           = 1
    #ami             = "ami-005bc7d72deb72a3d"
    ami             = data.aws_ami.ubuntu.id
    instance_type   = "t3.micro"
    key_name        = "martti_gc"
    security_groups = ["${aws_security_group.gcapp_sg.name}"]

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
        node_name       = self.public_dns
        #secret_key      = "${file("../encrypted_data_bag_secret")}" # nothing secret in my chef right now
        server_url      = "http://ec2-13-53-194-34.eu-north-1.compute.amazonaws.com:8889"
        recreate_client = true
        user_name       = "chef-bootstrap"
        user_key        = file("~/.ssh/martti_gc.pem")
        #version         = "12.4.1"
        ssl_verify_mode = ":verify_none"
    }

    # TODO workaround: upgrade machine after bootstrap, because before there was an apt conflict. Not sure why.
    provisioner "remote-exec" {
        script = "bootstrap.bash"
    }

    # output the public DNS name for ease of debugging
    provisioner "local-exec" {
        command = "echo ${self.public_dns} ${self.public_ip} ${self.instance_state}"
        on_failure = continue
    }
}