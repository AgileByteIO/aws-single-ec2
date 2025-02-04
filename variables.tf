variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "aws_account" {
  description = "Aws Account"
  type        = string
}

variable "aws_tofu_bucket" {
  description = "Tofu bucket"
  type        = string
}

variable "aws_name_tag" {
  description = "tag and Prefix for all aws resources"
  type        = string
}

variable "domain" {
  description = "your domain"
  type        = string
}

variable "app_port" {
  description = "exposed application port"
  type        = string
  default     = "3000"
}

variable "hosted_zone" {
  description = "existing hosted zone"
  type        = string
}

variable "email" {
  description = "Email your domain is registered with"
  type        = string
}

variable "aws_key_name" {
  description = "Name of the key pair to use for SSH access"
  type        = string
}

variable "aws_ec2_access_key_id" {
  description = "aws access key id"
  type        = string
}

variable "aws_ec2_secret_access_key" {
  description = "aws access key/ secret"
  type        = string
}

variable "aws_vpc_id" {
  description = "Id of vpc"
  type        = string
}

variable "aws_vpc_subnet_id" {
  description = "Id of vpc subnet"
  type        = string
}

variable "aws_mount_folder" {
  description = "s3 mount folder"
  type        = string
  default     = "mount_s3"
}

variable "aws_www_cert" {
  description = "www cert folder"
  type        = string
  default     = "/mount_s3/certs"
}

variable "aws_www_public" {
  description = "www public folder"
  type        = string
  default     = "/mount_s3/public"
}

variable "aws_www_private" {
  description = "www private folder"
  type        = string
  default     = "/mount_s3/private"
}

variable "aws_www_logs" {
  description = "s3 log folder"
  type        = string
  default     = "/mount_s3/logs"
}

variable "local_logs_folder" {
  description = "local log folder"
  type        = string
  default     = "/logs"
}

variable "certbot_renew_sh_file" {
  description = "k8s.yaml file"
  type        = string
  default     = "/etc/scripts/certbot_renew.sh"
}

variable "k8s_config_file" {
  description = "k8s.yaml file"
  type        = string
  default     = "/etc/k8s/deployment.yaml"
}

variable "certbot_www_folder" {
  description = "temp certbot folder"
  type        = string
  default     = "/certbot-www"
}
