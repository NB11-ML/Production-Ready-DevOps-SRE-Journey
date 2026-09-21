terraform {
  required_providers {
    aws={
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws"{
    region = "us-east-1"
}

resource "aws_s3_bucket" "terrabucketdev" {
    bucket = "terrabucketdev"
  
}

resource "aws_instance" "terraec2" {
    ami = "ami-0fef201115eefe936"
    instance_type = "t3.micro"
    tags = {
        Name = "TerraWeek-Modified" 
    }
  
}