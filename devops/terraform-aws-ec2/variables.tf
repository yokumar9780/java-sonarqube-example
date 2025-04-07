variable "environment" {
  type        = string
  description = "The environment to be built"
}
variable "application_name" {
  type        = string
  description = "Application name which will be used to prefix every created resource"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}
