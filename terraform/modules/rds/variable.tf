variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "aws3tier"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "private_db_subnet_id" {
  description = "First private DB subnet ID"
  type        = string
}

variable "private_db_subnet_2_id" {
  description = "Second private DB subnet ID"
  type        = string
}

variable "db_sg_id" {
  description = "Security group ID for the database"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "project1db"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}