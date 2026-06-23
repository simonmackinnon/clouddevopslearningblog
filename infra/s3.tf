resource "aws_s3_bucket" "blog" {
  bucket = local.domain
  tags   = { Project = local.project }
}

resource "aws_s3_bucket_website_configuration" "blog" {
  bucket = aws_s3_bucket.blog.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "blog" {
  bucket = aws_s3_bucket.blog.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Public read — required for S3 website hosting (no OAC on this legacy dist)
resource "aws_s3_bucket_policy" "blog" {
  bucket = aws_s3_bucket.blog.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Policy1590281479480"
    Statement = [{
      Sid       = "Stmt1590281476069"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.blog.arn}/*"
    }]
  })
}
