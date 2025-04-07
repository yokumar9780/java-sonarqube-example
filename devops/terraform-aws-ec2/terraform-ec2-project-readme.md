# Terraform AWS EC2 Deployment

This example the Terraform configuration for deploying an EC2 instance in AWS with appropriate networking, security, and IAM configurations.

## Overview

This Terraform project provisions:
- EC2 instance with Ubuntu Server 24.04 LTS
- Security Group with HTTP (80) and HTTPS (443) access
- Elastic IP for static public IP addressing
- IAM Role with SSM managed policy for secure instance management
- Uses an existing VPC and public subnet infrastructure

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- AWS CLI configured with appropriate access credentials
- AWS account with permissions to create the resources defined

## Project Structure

```
.
├── main.tf         # Main Terraform configuration file
├── variables.tf    # Variable definitions
├── outputs.tf      # Output definitions
├── user_data/
│   └── install_docker.sh  # Script for EC2 instance initialization
└── README.md       # This file
```

## Configuration

Before deployment, you need to create or update the following files:

### 1. Create `variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "application_name" {
  description = "Name of the application"
  type        = string
  default     = "webapp"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

### 2. Create `outputs.tf`:

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.ec2_eip.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security_group.security_group_id
}
```

### 3. Create `user_data/install_docker.sh`:

```bash
#!/bin/bash
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
systemctl enable docker
systemctl start docker
```

## Deployment Steps

1. Clone this repository to your local machine.

2. Navigate to the project directory:
   ```bash
   cd terraform-aws-ec2
   ```

3. Initialize the Terraform working directory:
   ```bash
   terraform init
   ```

4. Create a plan to verify the resources that will be created:
   ```bash
   terraform plan
   ```

5. Apply the Terraform configuration to provision the resources:
   ```bash
   terraform apply
   ```

6. Confirm the deployment by typing `yes` when prompted.

7. After successful deployment, Terraform will output the instance's public IP and other information defined in `outputs.tf`.

## Accessing the EC2 Instance

The EC2 instance is configured to use AWS Systems Manager Session Manager for secure access without SSH keys. To connect:

1. Make sure you have the AWS CLI and Session Manager plugin installed:
   ```bash
   aws ssm start-session --target [instance-id]
   ```

2. Alternatively, you can access the instance through the AWS Management Console using EC2 Instance Connect.

## Clean Up

To destroy all resources created by this Terraform configuration:

```bash
terraform destroy
```

Confirm the destruction by typing `yes` when prompted.

## Security Considerations

- The security group allows inbound traffic on ports 80 (HTTP) and 443 (HTTPS) from any IP address (0.0.0.0/0). Consider restricting these to specific IP ranges in a production environment.
- IAM permissions follow the principle of least privilege with only the necessary SSM managed policy attached.
- No SSH key is used; instead, AWS Systems Manager is leveraged for secure instance access.

## Notes

- This configuration uses an existing VPC with ID `vpc-0f16a99057c232aec`.
- Ubuntu Server 24.04 LTS AMI is used (`ami-0d64bb532e0502c46`).
- The EC2 instance is deployed with an 80GB gp3 root volume.
