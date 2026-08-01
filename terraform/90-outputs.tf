output "aws_region" {
  description = "AWS region used by the template."
  value       = var.aws_region
}

output "api_base_url" {
  description = "Base URL for the deployed REST API stage."
  value       = "https://${aws_api_gateway_rest_api.lab.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "api_stage_arn" {
  description = "Regional API Gateway stage ARN used by AWS WAF."
  value       = aws_api_gateway_stage.prod.arn
}

output "user_pool_id" {
  description = "Cognito user pool ID."
  value       = aws_cognito_user_pool.lab.id
}

output "cognito_client_id" {
  description = "Public Cognito app client ID."
  value       = aws_cognito_user_pool_client.lab.id
}

output "cognito_groups" {
  description = "Cognito groups created by the template."
  value = {
    students = aws_cognito_user_group.students.name
    admins   = aws_cognito_user_group.admins.name
    security = aws_cognito_user_group.security.name
  }
}

output "api_scopes" {
  description = "Custom scopes enforced by API Gateway."
  value = {
    python   = local.python_scope
    node     = local.node_scope
    security = local.security_scope
  }
}

output "token_tracking_table" {
  description = "DynamoDB table that tracks access-token use."
  value       = aws_dynamodb_table.token_tracking.name
}

output "waf_events_table" {
  description = "DynamoDB table containing normalized WAF events."
  value       = aws_dynamodb_table.waf_events.name
}

output "waf_log_group" {
  description = "CloudWatch log group receiving WAF traffic logs."
  value       = aws_cloudwatch_log_group.waf.name
}

output "waf_analyzer_function" {
  description = "Lambda function that normalizes and analyzes recent WAF logs."
  value       = aws_lambda_function.waf_analyzer.function_name
}

output "unused_token_detector_function" {
  description = "Scheduled unused-token detector Lambda function."
  value       = aws_lambda_function.unused_token_detector.function_name
}

output "unused_token_minutes" {
  description = "Age in minutes after which an unused token becomes alertable."
  value       = var.unused_token_minutes
}

output "unused_token_rule" {
  description = "EventBridge rule that schedules the unused-token detector."
  value       = aws_cloudwatch_event_rule.unused_token_check.name
}

output "alert_topic_arn" {
  description = "SNS topic receiving security lab alerts."
  value       = aws_sns_topic.security_alerts.arn
}

output "waf_correlation_findings_table" {
  description = "DynamoDB table containing Lab 12 correlation findings."
  value       = aws_dynamodb_table.waf_correlation_findings.name
}

output "security_incidents_table" {
  description = "DynamoDB table containing Lab 12a incidents."
  value       = aws_dynamodb_table.security_incidents.name
}

output "waf_correlation_function" {
  description = "Manually invoked Lab 12 WAF correlation Lambda."
  value       = aws_lambda_function.waf_correlation.function_name
}

output "soar_response_function" {
  description = "EventBridge-invoked Lab 12a SOAR Lambda."
  value       = aws_lambda_function.soar_response.function_name
}

output "report_generator_function" {
  description = "Manually invoked Lab 12b report generator Lambda."
  value       = aws_lambda_function.report_generator.function_name
}

output "report_bucket" {
  description = "Private S3 bucket receiving Lab 12b reports."
  value       = aws_s3_bucket.reports.id
}

output "lambda_log_groups" {
  description = "Lambda log groups used during the demonstration."
  value = {
    python_api            = aws_cloudwatch_log_group.python_api.name
    node_api              = aws_cloudwatch_log_group.node_api.name
    security_status       = aws_cloudwatch_log_group.security_api.name
    token_scope_control   = aws_cloudwatch_log_group.pre_token.name
    unused_token_detector = aws_cloudwatch_log_group.unused_token_detector.name
    waf_analyzer          = aws_cloudwatch_log_group.waf_analyzer.name
    waf_correlation       = aws_cloudwatch_log_group.waf_correlation.name
    soar_response         = aws_cloudwatch_log_group.soar_response.name
    report_generator      = aws_cloudwatch_log_group.report_generator.name
  }
}
