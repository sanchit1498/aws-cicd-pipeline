terraform {
  backend "s3" {
    bucket       = "sanchit-cicd-tfstate-816832911710"
    key          = "aws-cicd-pipeline/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}