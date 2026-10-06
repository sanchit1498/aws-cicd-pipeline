variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "aws3tier"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023, us-east-2)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance into"
  type        = string
}

variable "web_sg_id" {
  description = "Security group ID to attach to the instance"
  type        = string
}

variable "key_name" {
  description = "Name of the existing EC2 key pair for SSH access"
  type        = string
}