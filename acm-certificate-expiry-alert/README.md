# README #

## ACM Certificate Expiry Handler ##

This repository contains Terraform code to set up an AWS Lambda function that monitors ACM (AWS Certificate Manager) certificates for expiration. The Lambda function sends notifications via SNS (Simple Notification Service) when a certificate is approaching its expiration date.

## Features

- Automatically detects ACM certificates that are nearing expiration.
- Sends notifications through SNS when certificates are expiring.
- Integrates with AWS Security Hub to log findings about expiring certificates.

## Architecture Overview

- **AWS Lambda**: A serverless function that runs the certificate expiry handler.
- **Amazon SNS**: A topic to send notifications about expiring certificates.
- **Amazon EventBridge (CloudWatch Events)**: A rule that triggers the Lambda function when ACM certificates approach expiration.

## Prerequisites

- Terraform installed on your local machine.
- AWS account with appropriate permissions to create IAM roles, Lambda functions, SNS topics, and EventBridge rules.
- An existing ACM certificate that you want to monitor.

## Configuration

**Variables**: You can customize the behavior of the Lambda function by modifying the following variables in your Terraform code:

| **Variable**   | **Description**                                                      | **Type** | **Default** |
|----------------|----------------------------------------------------------------------|----------|-------------|
| `region`       | AWS region to provision the resources                                | string   | ""          |
| `email`        | Email-id for the SNS notification alert                              | string   | ""          |
| `expiry_days`  | Number of days before expiration to send alerts for ACM certificates | number   | 15          |

> ## NOTE:
> Ensure you have the AWS CLI configured with credentials that have permissions to create resources.

## Deploying the Infrastructure

1. Clone this repository to your local machine.

   ```bash
   aws sts get-caller-identity # To check whether i am federated to correct account to deploy infrastructure
   git clone https://github.com/faizu6/terraform.git
   cd terraform/acm-certificate-expiry-alert
   # update the `variables.tf` file as per requirement
   terraform init
   terraform plan
   terraform apply
> ## Deploying the Infrastructure in multiple accounts
If you want to deploy the infrastructure in multiple accounts handling the `terraform.tfstate` file would be hectic. To handle that we can use **terraform workspaces**

If the alert is to be deployed in 3 accounts we will create 3 workspaces and 3 different variable files and create backend to handle configurations/statefiles.

> backend.tf file make sure you have a bucket created with the name and the bucket name is added as a variable in the respective variable.tf file

  ```bash
  terraform {
  backend "s3" {
    bucket         = var.bucket
    key            = "terraform/state/${terraform.workspace}.tfstate"
    region         = var.region
   }
}
  ```
To create a workspace for different account 
you handle the var files separately like `account1.tfvars`, `account2.tfvars` etc. Run the below commands to execute the script in multiple account and handle the statefiles gracefully

```bash
terraform workspace new account1
terraform workspace new account2

# Switch to account1 workspace
terraform workspace select account1

# Apply the configuration with account1 variables
terraform apply -var-file="account1.tfvars"

# Switch to account2 workspace
terraform workspace select account2

# Apply the configuration with account2 variables
terraform apply -var-file="account2.tfvars"
