output "sns_topic_arn" {
  value = aws_sns_topic.acm_certificate_expiry_alerts.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.acm_certificate_expiry_handler.arn
}

output "iam_role_arn" {
  value = aws_iam_role.acm_certificate_expiry_lambda_execution_role.arn
}

output "cloudwatch_event_rule_arn" {
  value = aws_cloudwatch_event_rule.acm_certificate_expiry_event_rule.arn
}

output "cloudwatch_event_target_id" {
  value = aws_cloudwatch_event_target.acm_certificate_lambda_target.id
}

