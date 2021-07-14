provider "aws" {
  region = "eu-west-1"
}

# Variables normalement dans un autre fichier (variables.tf) mais pour faire simple... ca marche aussi !!!
variable "env" {
  type    = string
  default = "dev"
}

####################################################################
# On recherche la derniere AMI créée avec le Name TAG ChatServerAMI
data "aws_ami" "selected" {
  owners = ["self"]
  filter {
    name   = "state"
    values = ["available"]

  }
  filter {
    name   = "tag:Name"
    values = ["ChatServerAMI"]
  }
  most_recent = true
}

# On recupere les ressources reseau
## VPC
data "aws_vpc" "selected" {
  tags = {
    Name = "${var.env}-vpc"
  }
}

## Subnets
data "aws_subnet" "subnet-public-1" {
  tags = {
    Name = "${var.env}-subnet-public-1"
  }
}

## AZ zones de disponibilités dans la région
data "aws_availability_zones" "all" {}

########################################################################
## SG Rule chat_server_sg
resource "aws_security_group" "chat_server_sg" {

  name        = "chat_server_sg"
  description = "Allow TCP 5555 & SSH inbound traffic"
  vpc_id      = data.aws_vpc.selected.id
  
  ingress {
    description      = "5555 from EFREI_GROUP"
    from_port        = 5555
    to_port          = 5555
    protocol         = "tcp"
    cidr_blocks      = ["82.64.73.178/32","90.3.0.106/32","176.158.166.180/32","80.215.38.198/32","88.123.159.229/32","80.215.166.202/32"]
  }
  
  ingress {
    description      = "SSH for me"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["82.64.73.178/32","90.3.0.106/32","176.158.166.180/32","80.215.38.198/32","88.123.159.229/32","10.0.4.0/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "java_server" {
  ami           = data.aws_ami.selected.id
  subnet_id		= data.aws_subnet.subnet-public-1.id
  vpc_security_group_ids = [aws_security_group.chat_server_sg.id]
  key_name		= "tp_jenkins"

  instance_type = "t2.micro"

  tags = {
    Name = "JavaChatServer"
  }
}

## On revoie l'IP du serveur pour s'y connecter
output "server_public_ip" {
  description = "The public IP of the Server"
  value       = aws_instance.java_server.public_ip
}
