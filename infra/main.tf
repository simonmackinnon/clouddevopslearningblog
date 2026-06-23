terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    region = "ap-southeast-2"
    key    = "blog/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

# ACM certificates must live in us-east-1 for CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  project = "blog"
  domain  = var.domain
}
