terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  common_tags = {
    Environment = "Dev"
    Project     = "TerraWeek"
    ManagedBy   = "Terraform"
    Challenge   = "90DaysOfDevOps"
  }
}
