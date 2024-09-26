terraform {
  backend "s3" {
    bucket  = "terraform-devops---rssc"
    key     = "state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

data "aws_s3_bucket" "existing_bucket" {
  bucket = "terraform-devops---rssc" # Reference your existing bucket name
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = data.aws_s3_bucket.existing_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::145023129007:role/GithubActionsRole"
        }
        Action = "s3:*"
        Resource = [
          data.aws_s3_bucket.existing_bucket.arn,
          "${data.aws_s3_bucket.existing_bucket.arn}/*"
        ]
      }
    ]
  })
}