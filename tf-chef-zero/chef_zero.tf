provider "aws" {
    region = "eu-north-1"
}

resource "aws_security_group" "chefzero_sg" {
    name        = "chefzero_sg"
    description = "SG for chef-zero playing a server"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
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

# get the latest ubuntu 18.04 LTS image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# fake chef server with chef-zero
resource "aws_instance" "chefserver" {
    count           = 1
    ami             = data.aws_ami.ubuntu.id
    instance_type   = "t3.micro"
    key_name        = "martti_gc"
    security_groups = ["${aws_security_group.chefzero_sg.name}"]

    provisioner "remote-exec" {
        script = "chef-zero-bootstrap.bash"

        connection {
            user = "ubuntu"
            private_key = file("~/.ssh/martti_gc.pem")
            host = self.public_ip
        }
    }

    # display the hostname at the end to save time for querying it afterwards
    provisioner "local-exec" {
        command = "echo ${self.public_dns} ${self.public_ip} ${self.instance_state}"
        on_failure = continue
    }
}