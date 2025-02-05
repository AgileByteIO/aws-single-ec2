# Terraform Configuration for WebApp EC2 Instance
This Terraform configuration sets up a single EC2 instance to host a web application. It is designed to be simple, reusable, and easy to integrate into your existing web application project. The configuration provisions an EC2 instance, configures networking, and sets up DNS records using Route 53. The application is SSL protected.
## Prerequisites
Before using this Terraform configuration, ensure the following prerequisites are met:
### AWS CLI: Install and configure the AWS CLI with the necessary credentials and permissions.
[Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
[Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
### Terraform or OpenTofu: Install Terraform or OpenTofu on your local machine.
[Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
[OpenTofu](https://opentofu.org/) (if using OpenTofu instead of Terraform)
### AWS Resources
* An S3 bucket for storing Terraform state files.
* A VPC and subnet configured in your AWS account.
* A Route 53 hosted zone for DNS management.
* IAM permissions to deploy EC2 instances, KMS keys, S3 buckets, and Route 53 records.
### Docker file
Your-webapp-project should have a Dockerfile with the port 3000 exposed. 
## Getting Started
### Step 1: Clone the Repository
Clone this repository into a subfolder of your web application project:
> git clone https://github.com/AgileByteIO/aws-single-ec2.git ./<your-webapp-project>/terraform

> cd ./<your-webapp-project>/terraform
### Step 2: Configure terraform.tfvars
Create a terraform.tfvars file in the root of the cloned repository with the following variables:
#### Input Variables	
| Name | Description |
| --- | --- |             
| aws_account | Your AWS account ID. |
| aws_tofu_bucket | Name of the S3 bucket for storing Terraform state files |
| aws_name_tag | Name tag for AWS resources (e.g., "webapp-prod") |
| domain | Domain name for your web application (e.g., "app.example.com") |
| hosted_zone |	Route 53 hosted zone ID for the domain |
| email	| Email address for notifications (e.g., SSL certificate alerts) |
| aws_vpc_id | ID of the VPC where the EC2 instance will be deployed |
| aws_vpc_subnet_id | ID of the subnet within the VPC for the EC2 instance |
### Step 3: Initialize Terraform
Initialize Terraform to download the required providers and modules:
> terraform init
### Step 4: Review and Apply
Review the execution plan:
> terraform plan
If the plan looks correct, apply the configuration:
>terraform apply
### Step 5: Access Your WebApp
Once the Terraform configuration is applied, your EC2 instance will be provisioned, and a DNS record will be created in Route 53. You can access your web application using the domain specified in the terraform.tfvars file.
#### Outputs Variable
After applying the Terraform configuration, the following outputs will be displayed:
| Name | Description |
| --- | --- |  
| instance_id | Instance identifier |
| instance_public_ip | Public IP address (use for ssh) |
| repository_url | ECR Repository of your application docker |
| bucket_id | Bucket identifier |
## Ensure the AWS user or role running this Terraform configuration has the following permissions:
* ec2:*
* s3:*
* route53:*
* kms: *
## Contributing
Contributions are welcome! If you'd like to contribute, please:
* Fork the repository.
* Create a new branch for your feature or bug fix.
* Submit a pull request with a detailed description of your changes.
## TODO
* Connection application to public and private folder on s3
* Testing (This in apha status)
* Redeployment for application layer
* Monitoring
## License
This project is licensed under the [MIT License](/LICENSE).