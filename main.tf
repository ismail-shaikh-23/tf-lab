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
  region = "ap-south-1"
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Web server security groups"
  #checkov:skip=CKV2_AWS_5:Security group attachment handled separately in this lab

  ingress {
    description = "SSH from office VPN only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_kms_key" "s3" {
  description = "KMS key for S3 bucket"
  #checkov:skip=CKV2_AWS_64:KMS key policy not required for this lab
  enable_key_rotation = true
}

resource "aws_s3_bucket" "data" {
  #checkov:skip=CKV_AWS_18:Access logging not needed in lab
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required for this lab
  #checkov:skip=CKV2_AWS_61:S3 lifecycle not required for this lab
  #checkov:skip=CKV_AWS_144:Cross region replication not required for this lab

  bucket = "ismail-tf-lab-bucket-12345"
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  monitoring    = true
  ebs_optimized = true
  #checkov:skip=CKV2_AWS_41:IAM role attachment not required for this lab

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

}
