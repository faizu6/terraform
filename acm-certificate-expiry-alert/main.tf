provider "aws" {
  region = var.region 
}

data "aws_caller_identity" "current" {}

# IAM Policy
resource "aws_iam_policy" "acm_certificate_expiry_policy_for_lambda" {
  name        = "acm_certificate_expiry_policy_for_lambda"
  description = "IAM policy for Lambda Certificate Expiry"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "LambdaCertificateExpiryPolicy1"
        Effect    = "Allow"
        Action    = "logs:CreateLogGroup"
        Resource = format("arn:aws:logs:us-east-1:%s:*", data.aws_caller_identity.current.account_id)
      },
      {
        Sid       = "LambdaCertificateExpiryPolicy2"
        Effect    = "Allow"
        Action    = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          format("arn:aws:logs:us-east-1:%s:log-group:/aws/lambda/handle-expiring-certificates:*", data.aws_caller_identity.current.account_id)
        ]
      },
      {
        Sid       = "LambdaCertificateExpiryPolicy3"
        Effect    = "Allow"
        Action    = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate"
        ]
        Resource  = "*"
      },
      {
        Sid       = "LambdaCertificateExpiryPolicy4"
        Effect    = "Allow"
        Action    = "SNS:Publish"
        Resource  = "*"
      },
      {
        Sid       = "LambdaCertificateExpiryPolicy5"
        Effect    = "Allow"
        Action    = [
          "SecurityHub:BatchImportFindings",
          "SecurityHub:BatchUpdateFindings",
          "SecurityHub:DescribeHub"
        ]
        Resource  = "*"
      },
      {
        Sid       = "LambdaCertificateExpiryPolicy6"
        Effect    = "Allow"
        Action    = "cloudwatch:ListMetrics"
        Resource  = "*"
      }
    ]
  })
}

# SNS Topic
resource "aws_sns_topic" "acm_certificate_expiry_alerts" {
  name = "acm-certificate-expiry-alerts"
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "acm_certificate_expiry_alerts_subscription" {
  topic_arn = aws_sns_topic.acm_certificate_expiry_alerts.arn
  protocol  = "email"
  endpoint  = var.email
}

# Lambda Function
resource "aws_lambda_function" "acm_certificate_expiry_handler" {
  function_name    = "acm-certificate-expiry-handler"
  handler          = "acm-cert-expiry-code.lambda_handler"
  runtime          = "python3.11"
  filename         = "lambda_function_payload.zip" 
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
  timeout = 30
  role = aws_iam_role.acm_certificate_expiry_lambda_execution_role.arn
  environment {
    variables = {
      EXPIRY_DAYS   = var.expiry_days
      SNS_TOPIC_ARN = aws_sns_topic.acm_certificate_expiry_alerts.arn
    }
  }
}

# IAM Role
resource "aws_iam_role" "acm_certificate_expiry_lambda_execution_role" {
  name = "acm-certificate-expiry-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attaching Policy to Role
resource "aws_iam_role_policy_attachment" "acm_certificate_expiry_lambda_policy_attachment" {
  role       = aws_iam_role.acm_certificate_expiry_lambda_execution_role.name
  policy_arn = aws_iam_policy.acm_certificate_expiry_policy_for_lambda.arn
}

# CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "acm_certificate_expiry_event_rule" {
  name        = "certificate-expiry-event-rule"
  description = "Event rule for ACM Certificate Expiry"
  event_pattern = jsonencode({
    "source"  : ["aws.certificatemanager"],
    "detail"  : {
      "eventName": ["ACM Certificate Approaching Expiration"]
    }
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "acm_certificate_lambda_target" {
  rule      = aws_cloudwatch_event_rule.acm_certificate_expiry_event_rule.name
  target_id = "certificate-expiry-lambda-target"
  arn       = aws_lambda_function.acm_certificate_expiry_handler.arn
}

