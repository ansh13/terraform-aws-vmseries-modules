## 1. Provider and Terraform Setup
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region # <-- Uses variable for region
}


## 2. Data Sources (Automated Lookups)

# 🔎 Data Source: Find the Existing VPC by Name Tag
# Retrieves the ID of the VPC based on the 'vpc_name_tag' variable.
data "aws_vpc" "existing_vpc" {
  tags = {
    Name = var.vpc_name_tag # <-- Uses variable for VPC name
  }
}

# 🔎 Data Source: Find the Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}


## 3. Network Resources (Creation)

#  Resource: Create a New Subnet in the Found VPC
resource "aws_subnet" "new_subnet" {
  # Uses the ID retrieved from the aws_vpc data source
  vpc_id                  = data.aws_vpc.existing_vpc.id 
  cidr_block              = var.new_subnet_cidr    # <-- Uses variable for CIDR
  availability_zone       = "${var.aws_region}b"   # Sets AZ based on region variable
  map_public_ip_on_launch = false                     

  tags = {
    Name = "terraform-created-subnet"
  }
}

# Resource: Create a Basic Security Group (for SSH and HTTP access)
resource "aws_security_group" "ssh_http" {
  name        = "ssh_http_access1"
  description = "Allow SSH and HTTP inbound traffic"
  # Uses the ID retrieved from the aws_vpc data source
  vpc_id      = data.aws_vpc.existing_vpc.id 

  # Inbound SSH Access (Port 22)
  ingress {
    description = "SSH from Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Outbound Access (All traffic allowed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh_http_sg"
  }
}


## 4. Compute Resource (EC2 Instance)

# 🚀 Resource: Launch the Linux VM (EC2 Instance)
resource "aws_instance" "linux_vm" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro" 
  # References the ID of the newly created subnet
  subnet_id     = aws_subnet.new_subnet.id 
  vpc_security_group_ids = [aws_security_group.ssh_http.id]
  associate_public_ip_address = true
  
  # NEW: Explicitly define the root volume as gp3 to satisfy the IAM policy
  root_block_device {
    volume_type = "gp3"
    volume_size = 8 # Or your desired size
    encrypted   = true # Best practice
  }

  key_name = var.key_pair_name # <-- Uses variable for Key Pair name

  tags = {
    Name = "New-Subnet-Linux-VM"
  }
}

# 💡 Output the Public IP
output "vm_public_ip" {
  description = "The public IP address of the launched Linux VM"
  value       = aws_instance.linux_vm.public_ip
}