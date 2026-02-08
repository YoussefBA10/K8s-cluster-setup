provider "aws" {
  region = "us-east-1"
}

# Velero backup bucket
resource "aws_s3_bucket" "velero_backups" {
  bucket = "rock-solid-backups"
  
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Velero Backups"
    Environment = "Production"
    Tool        = "Velero"
  }
}

# Postgres backup bucket
resource "aws_s3_bucket" "postgres_backups" {
  bucket = "rock-solid-postgres-backups"

  tags = {
    Name        = "Postgres Backups"
    Environment = "Production"
    Tool        = "Postgres-Sidecar"
  }
}


resource "aws_s3_bucket_versioning" "velero_versioning" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "velero_block_public" {
  bucket = aws_s3_bucket.velero_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "postgres_block_public" {
  bucket = aws_s3_bucket.postgres_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
