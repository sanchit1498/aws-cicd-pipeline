variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "aws3tier"
}

variable "vpc_id" {
  description = "ID of the VPC these security groups belong to"
  type        = string
}

variable "my_ip" {
  description = "Your IP address in CIDR notation, for SSH access"
  type        = string
}