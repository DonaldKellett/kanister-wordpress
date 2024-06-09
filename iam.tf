resource "aws_iam_policy" "kanister-wordpress" {
  name        = "kanister-wordpress"
  description = "Policy for kanister-wordpress-${random_id.kanister-wordpress-suffix.hex} S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.kanister-wordpress.arn,
          "${aws_s3_bucket.kanister-wordpress.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_group" "kanister-wordpress" {
  name = "kanister-wordpress"
}

resource "aws_iam_group_policy_attachment" "kanister-wordpress" {
  group      = aws_iam_group.kanister-wordpress.name
  policy_arn = aws_iam_policy.kanister-wordpress.arn
}

resource "aws_iam_user" "kanister-wordpress" {
  name = "kanister-wordpress"
}

resource "aws_iam_user_group_membership" "kanister-wordpress" {
  user   = aws_iam_user.kanister-wordpress.name
  groups = [aws_iam_group.kanister-wordpress.name]
}

resource "aws_iam_access_key" "kanister-wordpress" {
  user = aws_iam_user.kanister-wordpress.name
}
