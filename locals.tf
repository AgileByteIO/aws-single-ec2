resource "null_resource" "this" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
    # Build the Docker image
    docker build -t ${var.aws_name_tag}-landingpage -f ../Dockerfile ../

    # Authenticate Docker to ECR
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}

    # Tag the image
    docker tag ${var.aws_name_tag}-landingpage:latest ${aws_ecr_repository.this.repository_url}:latest

    # Push the image to ECR
    docker push ${aws_ecr_repository.this.repository_url}:latest
  EOT
  }
  depends_on = [aws_ecr_repository.this]
}

locals {
  cloudinit_config_files = jsonencode({
    write_files = [
      {
        path        = var.certbot_renew_sh_file
        permissions = "0544"
        owner       = "root:root"
        content     = <<-EOF
#!/bin/sh

sudo certbot certonly --webroot --renew-by-default --agree-tos --email ${var.email} -d ${var.domain} --logs-dir ${var.local_logs_folder} --webroot-path ${var.certbot_www_folder}
cp -r /etc/letsencrypt/archive/${var.domain} ${var.aws_www_cert}
        EOF
      },
      {
        path        = var.k8s_config_file
        permissions = "0444"
        owner       = "root:root"
        content     = <<-EOF
apiVersion: v1
kind: ConfigMap
metadata:
name: nginx-conf
labels:
  app: landingpage
data:
nginx.conf: |
  user nginx;
  worker_processes  3;
  error_log  /var/log/nginx/error.log;
  events {
    worker_connections  10240;
  }
  http {
    log_format  main
      'remote_addr:$remote_addr\t'
      'time_local:$time_iso8601\t'
      'method:$request_method\t'
      'uri:$request_uri\t'
      'host:$host\t'
      'status:$status\t'
      'bytes_sent:$body_bytes_sent\t'
      'referer:$http_referer\t'
      'useragent:$http_user_agent\t'
      'forwardedfor:$http_x_forwarded_for\t'
      'request_time:$request_time';
    server {
      listen 80;
      listen [::]:80;
      server_name   ${var.domain};
      location /.well-known/acme-challenge/ {
        root /var/www/certbot;
      }
      location / {
        return 301 https://$host$request_uri;
      }
    }  
    server {
      listen 443 ssl;
      listen [::]:443 ssl; 
      http2 on;
      server_name         ${var.domain};
      ssl_certificate     /certs/${var.domain}/cert1.pem;
      ssl_certificate_key /certs/${var.domain}/privkey1.pem;
      ssl_session_cache   shared:SSL:10m;
      ssl_session_timeout 1h;
      ssl_buffer_size     8k;
      access_log  /var/log/nginx/access.log;
      # Example of reverse proxy, separate front end and back end
      location / {
        proxy_pass  http://$server_addr:3000$request_uri; # Local back end
      }
      # Serve the built front end assets
      location  /static/ {
        root  /usr/share/nginx/html/;
      }
    }
  }
---
apiVersion: apps/v1
kind: Deployment
metadata:
name: landingpage-deployment
labels:
  app: landingpage
spec:
replicas: 1
selector:
  matchLabels:
    app: landingpage
template:
  metadata:
    labels:
      app: landingpage
  spec:
    containers:
      - name: nginx-proxy
        image: public.ecr.aws/nginx/nginx:1.27
        ports:
          - containerPort: 80
            hostPort: 80
          - containerPort: 443
            hostPort: 443
        volumeMounts:
          - name: nginx-conf
            mountPath: /etc/nginx
            readOnly: true
          - name: certbotwww
            mountPath: /var/www/certbot
            readOnly: false
          - name: logs
            mountPath: /var/log/nginx
            readOnly: false
          - name: certs
            mountPath: /certs 
            readOnly: true
          - name: public
            mountPath: /usr/share/nginx/html
      # Add your application container configuration here
      - name: landigpage-app
        image: ${aws_ecr_repository.this.repository_url}
        ports:
          - containerPort: 3000  
            hostPort: 3000
    volumes:
      - name: nginx-conf
        configMap:
          name: nginx-conf # place ConfigMap `nginx-conf` on /etc/nginx
          items:
            - key: nginx.conf
              path: nginx.conf
      - name: logs
        hostPath:
          path: ${var.local_logs_folder}
      - name: certs
        hostPath:
          path: ${var.aws_www_cert}
      - name: certbotwww
        hostPath:
          path: ${var.certbot_www_folder}
      - name: public
        hostPath: 
          path: ${var.aws_www_public}
      - name: private
        hostPath: 
          path: ${var.aws_www_private}   
EOF
      },
    ]
  })
}
