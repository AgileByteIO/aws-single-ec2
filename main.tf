data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                  = "${var.aws_name_tag}-ec2-landingpage-role"
  assume_role_policy    = data.aws_iam_policy_document.instance_assume_role_policy.json
  force_detach_policies = true
  tags                  = { Name : "${var.aws_name_tag}-ec2-landingpage" }
}

data "aws_iam_policy_document" "ec2" {
  source_policy_documents = [
    data.aws_iam_policy_document.access_s3.json,
    data.aws_iam_policy_document.access_ecr.json,
    data.aws_iam_policy_document.kms.json
  ]
}

resource "aws_iam_policy" "this" {
  name   = "${var.aws_name_tag}-police"
  policy = data.aws_iam_policy_document.ec2.json
  tags   = { Name : var.aws_name_tag }
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}

# The permissions required for the EC2 instance 
resource "aws_iam_instance_profile" "this" {
  name = "${var.aws_name_tag}-landingpage-ec2-profile"
  role = aws_iam_role.this.name
  tags = { Name : "${var.aws_name_tag}-ec2-landingpage" }
}

# Create a security group
resource "aws_security_group" "this" {
  vpc_id = var.aws_vpc_id
  name   = "${var.aws_name_tag}-landingpage-group"

  ingress {
    from_port   = 80 # Allow HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from any IP (consider security best practices)
  }

  ingress {
    from_port   = 443 # Allow HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from any IP (consider security best practices)
  }

  ingress {
    from_port   = 22 # Allow SSH
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from any IP (consider security best practices)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.aws_name_tag}-landingpage"
  }
}

data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    filename     = "cloud-config.yaml"
    content      = local.cloudinit_config_files
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "init.sh"
    content      = <<-EOF
              #!/bin/bash
              
              # Update package repository
              sudo apt-get update -y
              sudo apt-get upgrade -y 
              
              # Install Podman
              sudo apt-get install -y podman
              
              # Install cert
              sudo apt-get install -y certbot
              
              # Install AWS CLI
              sudo snap install aws-cli --classic
              
              # Install mount-s3 Software
              sudo apt install libfuse2
              wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.deb
              yes | sudo dpkg -i ./mount-s3.deb
              sudo rm -f ./mount-s3.deb
              
              # Create local log folder
              sudo mkdir ${var.local_logs_folder}
              
              # Create mount point to s3 bucket
              sudo mkdir ${var.aws_mount_folder} 
              mount-s3 ${aws_s3_bucket.this.id} ${var.aws_mount_folder} --allow-other --dir-mode 755 --file-mode 644 --incremental-upload 
              echo "mount point:${var.aws_mount_folder} READY"
              
              # Create certbot web folder 
              sudo certbot certonly --standalone --renew-by-default --non-interactive --agree-tos --email ${var.email} -d ${var.domain} --logs-dir ${var.local_logs_folder}
              sudo cp -r /etc/letsencrypt/archive/${var.domain} ${var.aws_www_cert}
              echo "cert for domain: ${var.domain} READY"
              
              # Create Container 
              aws ecr get-login-password --region ${var.aws_region} | podman login --username AWS --password-stdin ${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com
              sudo mkdir ${var.certbot_www_folder}
              podman play kube ${var.k8s_config_file}
              echo "pods installed:${var.k8s_config_file} READY"

              # Create and install cert renew crontab. 
              crontab -l > crontab_tmp
              echo "16 2 1,15 * * ${var.certbot_renew_sh_file}" >> crontab_tmp
              crontab crontab_tmp
              rm crontab_tmp
            EOF
  }
}

# Create the EC2 Instance in the specified VPC and subnet
resource "aws_instance" "this" {
  ami                         = "ami-0a628e1e89aaedf80" # Amazon linux 
  instance_type               = "t2.micro"              # Update instance type as required
  key_name                    = var.aws_key_name        # Your SSH key pair
  iam_instance_profile        = aws_iam_instance_profile.this.name
  subnet_id                   = var.aws_vpc_subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  associate_public_ip_address = true
  monitoring                  = true

  user_data = data.cloudinit_config.this.rendered

  tags = {
    Name = "${var.aws_name_tag}"
  }

  depends_on = [null_resource.this,
  aws_s3_bucket.this]
}

resource "aws_route53_record" "main" {
  zone_id = var.hosted_zone
  name    = var.domain
  type    = "A"
  ttl     = 300
  records = [aws_instance.this.public_ip]
}

resource "aws_route53_record" "www" {
  zone_id = var.hosted_zone
  name    = "www.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_route53_record.main.name
    zone_id                = aws_route53_record.main.zone_id
    evaluate_target_health = true
  }
}

