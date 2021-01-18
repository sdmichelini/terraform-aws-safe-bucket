locals {
  name = "${var.name}-${terraform.workspace}-${data.aws_region.current.name}"
  tags = merge({ "Environment" : terraform.workspace
  }, var.tags)
}

data "aws_region" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket = local.name
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = var.versioning_enabled
  }

  force_destroy = var.force_destroy

  tags = local.tags
}

data "aws_iam_policy_document" "bucket_policy" {
  # Taken from https://aws.amazon.com/blogs/security/how-to-prevent-uploads-of-unencrypted-objects-to-amazon-s3/
  # also want to allow the case where default encryption will be applied
  statement {
    sid       = "DenyIncorrectEncryptionHeader"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "StringEquals"
      values   = ["aws:kms"]
      variable = "s3:x-amz-server-side-encryption"
    }
  }

  statement {
    sid       = "DenyNotBucketOwnerFullControl"
    effect    = "Deny"
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "StringNotEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.bucket.bucket
  policy = data.aws_iam_policy_document.bucket_policy.json

  # workaround - https://github.com/hashicorp/terraform-provider-aws/issues/7628
  depends_on = [aws_s3_bucket_public_access_block.block_access]
}

resource "aws_s3_bucket_public_access_block" "block_access" {
  bucket                  = aws_s3_bucket.bucket.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}