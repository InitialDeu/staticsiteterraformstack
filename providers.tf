terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}


terraform {
  backend "s3" {
    bucket  = "sito-terraform-state"
    key     = "site-cdn/terraform.tfstate"
    region  = "eu-south-1"
    encrypt = true
  }
}