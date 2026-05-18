terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
  }
  backend "s3" {
    bucket = "pedrx-terraform-state-2025"
    key    = "aws-states/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-2"

}