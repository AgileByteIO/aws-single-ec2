output "instance_id" {
  value = aws_instance.this.id
}

output "instance_public_ip" {
  value = aws_instance.this.public_ip
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "bucket_id" {
  value = aws_s3_bucket.this.id
}
