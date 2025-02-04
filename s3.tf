data "aws_canonical_user_id" "current" {
}

# S3 Bucket Resource
resource "aws_s3_bucket" "this" {
  bucket        = "${var.aws_name_tag}-bucket" #  Unique bucket name
  force_destroy = true
  tags = {
    Name = "${var.aws_name_tag}-bucket"
  }
}

#resource "aws_s3_bucket_versioning" "this_versioning" {
#  bucket = aws_s3_bucket.this.id
#  versioning_configuration {
#    status = "Enabled"
#  }
#}

resource "aws_kms_key" "this_kms" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.this_kms.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = aws_s3_bucket.this.id
  access_control_policy {
    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ"
    }
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_object" "logs" {
  bucket = aws_s3_bucket.this.id
  key    = "logs/"
  source = "/dev/null"
}

resource "aws_s3_object" "private" {
  bucket = aws_s3_bucket.this.id
  key    = "private/"
  source = "/dev/null"
}

resource "aws_s3_object" "public" {
  bucket = aws_s3_bucket.this.id
  key    = "public/"
  source = "/dev/null"
}

resource "aws_s3_object" "certs" {
  bucket = aws_s3_bucket.this.id
  key    = "certs/"
  source = "/dev/null"
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid = "kms"

    actions = [
      "kms:*"
    ]

    resources = [
      aws_kms_key.this_kms.arn, "${aws_kms_key.this_kms.arn}/*"
    ]
  }
}


// Policy document to grant access to bucket
data "aws_iam_policy_document" "access_s3" {
  statement {
    sid = "s3"

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"
    ]
  }
}


