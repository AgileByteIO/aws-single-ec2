data "aws_vpc" "this" {
  id = var.aws_vpc_id
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  vpc_id = data.aws_vpc.this.id
  tags   = { Name : "${var.aws_name_tag}-landingpage" }

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      tags         = { Name = "s3-vpc-endpoint" }
    }
  }
}
