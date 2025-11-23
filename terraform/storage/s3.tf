resource "aws_s3_bucket" "microservice2_uploads" {
  bucket        = lower("${var.project_name}-ms2-uploads-${var.environment}-${random_id.unique_suffix.hex}")

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