# Create a new ECR repository
# Policy document to grant access to ecr repository
data "aws_iam_policy_document" "access_ecr" {
  statement {
    sid = "ecr"

    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_ecr_repository" "this" {
  name                 = "${var.aws_name_tag}-landingpage"
  image_tag_mutability = "MUTABLE" # Options: MUTABLE or IMMUTABLE
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "${var.aws_name_tag}-landingpage"
  }
}
