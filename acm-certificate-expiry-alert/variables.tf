variable "lambda_function_payload_file" {
  description = "File path to the Lambda function payload zip file"
  default     = "lambda_function_payload.zip"
}

variable "expiry_days" {
  description = "Number of days before certificate expiration to trigger alert"
  default     = 15
}


variable "region" {
  description = "Region in which the alert is to be deployed"
  default     = "us-east-1"
}

variable "email" {
  description = "email-id to which expiry alerts will be received"
  default     = "alerts@your-email.com"
}
