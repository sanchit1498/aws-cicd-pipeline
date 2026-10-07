terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
}

module "ec2" {
  source        = "./modules/ec2"
  project_name  = var.project_name
  ami_id        = var.ami_id
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnet_id
  web_sg_id     = module.security.web_sg_id
  key_name      = var.key_name
}

module "rds" {
  source                 = "./modules/rds"
  project_name           = var.project_name
  instance_class         = var.db_instance_class
  private_db_subnet_id   = module.vpc.private_db_subnet_id
  private_db_subnet_2_id = module.vpc.private_db_subnet_2_id
  db_sg_id               = module.security.db_sg_id
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
}
