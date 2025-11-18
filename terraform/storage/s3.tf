resource "aws_s3_bucket" "microservice2_uploads" {
  bucket = lower("${var.project_name}-ms2-uploads-${var.environment}")

  tags = {
    Name        = "${var.project_name}-ms2-uploads"
    Description = "S3 bucket for microservice 2 email content uploads"
  }
}

resource "aws_s3_bucket_versioning" "microservice2_uploads" {
  bucket = aws_s3_bucket.microservice2_uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "microservice2_uploads" {
  bucket = aws_s3_bucket.microservice2_uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public Access Block is commented out due to AWS Organization SCP restrictions
# Error: "explicit deny in a service control policy" for s3:PutBucketPublicAccessBlock
# The bucket will still be secure by default (private) without this resource.
# resource "aws_s3_bucket_public_access_block" "microservice2_uploads" {
#   bucket = aws_s3_bucket.microservice2_uploads.id
#
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }