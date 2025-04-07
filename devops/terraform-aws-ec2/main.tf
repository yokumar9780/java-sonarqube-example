terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.69.0"
    }
  }
}
provider "aws" {
  region = "eu-west-1" # Specify your region
}

locals {
  environment      = var.environment
  application_name = "${var.application_name}-${var.environment}"
  aws_region       = var.aws_region
  instance_type    = var.instance_type
}

# Automatically retrieve the AWS account ID using the STS caller identity data source
data "aws_caller_identity" "current" {}

# Look up the existing VPC by its ID
data "aws_vpc" "existing_vpc" {
  id = "vpc-0f16a99057c232aec"
}
data "aws_subnets" "public_subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

# Create a security group using terraform-aws-modules/security-group
module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "${local.application_name}-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

  description = "Security group for EC2 instance"
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}


# Create an EC2 instance using terraform-aws-modules/ec2-instance
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name          = "${local.application_name}-ec2"
  instance_type = var.instance_type
  ami = "ami-0d64bb532e0502c46" # Ubuntu Server 24.04 LTS
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id = data.aws_subnets.public_subnets.ids[0]   # Place instance in the first public subnet
  root_block_device = [
    {
      volume_size = 80    # Set the root volume size to 20 GB
      volume_type = "gp3" # General Purpose SSD
      delete_on_termination = true  # Automatically delete the volume when the instance is terminated
    }
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id # Attach the IAM Instance Profile
  associate_public_ip_address = true
  user_data = file("${path.module}/user_data/install_docker.sh")
  key_name = null # No SSH key, but we enable Instance Connect for access
  tags = {
    Name = local.application_name
  }
}


# Allocate an Elastic IP
resource "aws_eip" "ec2_eip" {
  domain   = "vpc"
  instance = module.ec2_instance.id
  tags = {
    Name = local.application_name
  }
}

# Create IAM Role for EC2 Instance Connect
resource "aws_iam_role" "ec2_role" {
  name = "${local.application_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}


# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.application_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
# Attach the policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ses_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

