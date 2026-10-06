variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "aws3tier"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_app_subnet_cidr" {
  description = "CIDR block for the private app subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_db_subnet_cidr" {
  description = "CIDR block for the first private db subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_db_subnet_2_cidr" {
  description = "CIDR block for the second private db subnet"
  type        = string
  default     = "10.0.4.0/24"
}