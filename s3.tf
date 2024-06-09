resource "aws_s3_bucket" "kanister-wordpress" {
  bucket = "kanister-wordpress-${random_id.kanister-wordpress-suffix.hex}"
}
