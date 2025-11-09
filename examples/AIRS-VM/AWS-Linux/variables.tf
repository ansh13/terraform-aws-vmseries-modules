## variables.tf

# Existing VPC Name Tag
variable "vpc_name_tag" {
  description = "The Name tag of the existing VPC to launch resources into."
  type        = string
}

# New Subnet CIDR Block
variable "new_subnet_cidr" {
  description = "The CIDR block for the new subnet."
  type        = string
  default     = "10.100.5.0/24"
}

# AWS Key Pair Name for SSH
variable "key_pair_name" {
  description = "The name of the existing AWS Key Pair for SSH access."
  type        = string
}

# AWS Region
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}