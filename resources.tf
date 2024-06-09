resource "local_sensitive_file" "kanister-wordpress-secret" {
  content         = <<EOT
---
apiVersion: v1
data:
  aws_access_key_id: ${base64encode(aws_iam_access_key.kanister-wordpress.id)}
  aws_secret_access_key: ${base64encode(aws_iam_access_key.kanister-wordpress.secret)}
  role: ""
kind: Secret
metadata:
  name: wordpress-s3-secret
  namespace: kanister
type: Opaque
EOT
  filename        = "${path.module}/manifests/secret.yaml"
  file_permission = "0600"
}

resource "local_file" "kanister-wordpress-profile" {
  content         = <<EOT
---
apiVersion: cr.kanister.io/v1alpha1
credential:
  keyPair:
    idField: aws_access_key_id
    secret:
      name: wordpress-s3-secret
      namespace: kanister
    secretField: aws_secret_access_key
  type: keyPair
kind: Profile
location:
  bucket: ${aws_s3_bucket.kanister-wordpress.bucket}
  region: ${var.region}
  type: s3Compliant
metadata:
  name: wordpress-s3-profile
  namespace: kanister
skipSSLVerify: false
EOT
  filename        = "${path.module}/manifests/profile.yaml"
  file_permission = "0666"
}
