terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.33.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
   tags = {
    Name = var.default_name
    }
  }
}
