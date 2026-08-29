terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "maxi-terraform-state-dev-123" 
    key            = "dev/infrastructure.tfstate"
    region         = "us-east-2"                     
    dynamodb_table = "terraform-state-locks"         
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}