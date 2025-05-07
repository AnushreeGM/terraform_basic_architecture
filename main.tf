#create custom vpc and subnets
#launch instances in subnets with security groups and NACLS (Network Access Control Lists)

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "eu-north-1"
}

#VPC
resource "aws_vpc" "UST-A-VPC" {
    cidr_block = "192.168.0.0/24"
    tags ={
        Name = "UST-A-VPC-tag"
    }
}

#Internet Gateway
resource "aws_internet_gateway" "UST-IGW" {
    vpc_id = aws_vpc.UST-A-VPC.id
    tags ={
        Name = "UST-IGW-tag"
    }
}

#Public Subnet
resource "aws_subnet" "UST-A-PubSub" {
    vpc_id = aws_vpc.UST-A-VPC.id
    cidr_block = "192.168.0.0/25"
    availability_zone = "eu-north-1a"
    tags ={
        Name = "UST-A-PubSub-tag"
    }
}

resource "aws_subnet" "UST-A-PriSub" {
    vpc_id = aws_vpc.UST-A-VPC.id
    cidr_block = "192.168.0.128/25"
    availability_zone = "eu-north-1b"
    tags ={
        Name = "UST-A-PriSub-tag"
    } 
}

#Route Table for PubSub
resource "aws_route_table" "UST-A-PubSub-RT" {
    vpc_id = aws_vpc.UST-A-VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.UST-IGW.id
    }
    tags = {
      Name = "UST-A-PubSub-RT-tag"
    } 
}

resource "aws_route_table" "UST-A-PriSub-RT" {
    vpc_id = aws_vpc.UST-A-VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.UST-A-VPC-NATGW.id
    }
    tags = {
        Name = "UST-A-PriSub-RT-tag"
    }
}

#Route Table Association for PubSub
resource "aws_route_table_association" "PubSub-RT-Assoc" {
    subnet_id = aws_subnet.UST-A-PubSub.id
    route_table_id = aws_route_table.UST-A-PubSub-RT.id
}

resource "aws_route_table_association" "PriSub-RT-Assoc" {
    subnet_id = aws_subnet.UST-A-PriSub.id
    route_table_id = aws_route_table.UST-A-PriSub-RT.id
}

#Elastic IP
resource "aws_eip" "eip-NAT-GW" {
    vpc = true
    tags = {
        Name = "UST-EIP-tag"
    }
}

#NAT Gateway
resource "aws_nat_gateway" "UST-A-VPC-NATGW" {
    allocation_id = aws_eip.eip-NAT-GW.id
    subnet_id = aws_subnet.UST-A-PubSub.id
    tags = {
      Name = "UST-A-VPC-NATGW-tag"
    }
}

#Security Group
resource "aws_security_group" "UST-A-SG" {
    vpc_id = aws_vpc.UST-A-VPC.id
    name = "UST-A-SG"
    description = "Allow SSH and HTTP"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#NACL
resource "aws_network_acl" "UST-A-VPC-NACL" {
    vpc_id = aws_vpc.UST-A-VPC.id
    ingress {
        rule_no = 100
        protocol = "-1"
        from_port = 0
        to_port = 0
        action = "allow"
        cidr_block = "0.0.0.0/0"
    }
    egress {
        rule_no = 100
        protocol = "-1"
        from_port = 0
        to_port = 0
        action = "allow"
        cidr_block = "0.0.0.0/0"
    }
}

#NACL Association with PubSub
resource "aws_network_acl_association" "NACL-PubSub" {
  subnet_id = aws_subnet.UST-A-PubSub.id
  network_acl_id = aws_network_acl.UST-A-VPC-NACL.id
}

#NACL Association with PriSub
resource "aws_network_acl_association" "NACL-PriSub" {
  subnet_id = aws_subnet.UST-A-PriSub.id
  network_acl_id = aws_network_acl.UST-A-VPC-NACL.id
}

#EC2 Instance Public Subnet
resource "aws_instance" "UST-A-PubSub-Instance" {
    ami = "ami-0dd574ef87b79ac6c"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.UST-A-PubSub.id
    security_groups = [aws_security_group.UST-A-SG.id]
    associate_public_ip_address = true
    user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>This is your Public Instance from Custom VPC UST-A-VPC</h1></body></html>" > /var/www/html/index.html
              EOF
    tags = {
        Name = "UST-A-PubSub-Instance-tag"
    }
}

#EC2 Instance Private Subnet
resource "aws_instance" "UST-A-PriSub-Instance" {
    ami = "ami-0dd574ef87b79ac6c"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.UST-A-PriSub.id
    security_groups = [aws_security_group.UST-A-SG.id]
    associate_public_ip_address = false
    user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<html><body><h1>This is your Private Instance from Custom VPC UST-A-VPC</h1></body></html>" > /var/www/html/index.html
              EOF
    tags = {
        Name = "UST-A-PriSub-Instance-tag"
    }
}

output "public_ec2_public_ip" {
    value = aws_instance.UST-A-PubSub-Instance.public_ip 
}
output "public_ec2_private_ip" {
    value = aws_instance.UST-A-PubSub-Instance.private_ip 
}
output "private_ec2_instance_id" {
    value = aws_instance.UST-A-PriSub-Instance.id
}
output "private_ec2_name" {
    value = aws_instance.UST-A-PriSub-Instance.tags["Name"]
}
output "private_ec2_private_ip" {
    value = aws_instance.UST-A-PriSub-Instance.private_ip 
  
}
