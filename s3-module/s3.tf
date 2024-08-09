# Terraform state storage  bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.team}-${random_pet.bucket_name.id}-${random_integer.bucket_int.result}"

  tags = {
    Name        = var.my_bucket
    Environment = var.env
  }
}

resource "random_pet" "bucket_name" {
  prefix = "wemadevops"
  length = 2
}

resource "random_integer" "bucket_int" {
  max = 500
  min = 1
}

# Release 2: SNS Topic
resource "aws_sns_topic" "topic" {
  name              = var.topic_name
  policy            = data.aws_iam_policy_document.topic.json
}

resource "aws_sns_topic_subscription" "email" {
  endpoint  = "example@domain.com"
  protocol  = "email"
  topic_arn = aws_sns_topic.topic.arn
}

# Release 3: Bucket Notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}


# Release : Bucket versioning
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.status
  }
}

# Release : Server-side encryption
resource "aws_kms_key" "mykmskey" {
  description             = "An example symmetric encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

resource "aws_kms_key_policy" "mykmskey-policy" {
  key_id = aws_kms_key.mykmskey.id
  policy = jsonencode({
    Id = "example"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }

        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykmskey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}