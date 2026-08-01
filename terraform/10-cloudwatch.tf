resource "aws_cloudwatch_log_group" "python_api" {
  name              = "/aws/lambda/${local.name_prefix}-python-api"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "node_api" {
  name              = "/aws/lambda/${local.name_prefix}-node-api"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "security_api" {
  name              = "/aws/lambda/${local.name_prefix}-security-status"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "pre_token" {
  name              = "/aws/lambda/${local.name_prefix}-token-scope-control"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "unused_token_detector" {
  name              = "/aws/lambda/${local.name_prefix}-unused-token-detector"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "waf_analyzer" {
  name              = "/aws/lambda/${local.name_prefix}-waf-analyzer"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${local.name_prefix}-api"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "waf_correlation" {
  name              = "/aws/lambda/${local.name_prefix}-waf-correlation"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "soar_response" {
  name              = "/aws/lambda/${local.name_prefix}-soar-response"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "report_generator" {
  name              = "/aws/lambda/${local.name_prefix}-report-generator"
  retention_in_days = var.log_retention_days
}
