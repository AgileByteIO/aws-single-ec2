terraform {
  backend "s3" {
    bucket  = var.aws_tofu_bucket
    key     = "${var.aws_name_tag}-landingpage.tf"
    region  = var.aws_region
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region # Replace with your desired region
}
