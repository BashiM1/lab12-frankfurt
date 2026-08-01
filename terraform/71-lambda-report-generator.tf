resource "aws_lambda_function" "report_generator" {
  function_name    = "${local.name_prefix}-report-generator"
  role             = aws_iam_role.report_generator.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/report-generator-with-dependencies.zip"
  source_code_hash = filebase64sha256("${path.module}/report-generator-with-dependencies.zip")
  timeout          = 120
  memory_size      = 1024

  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name
      REPORT_BUCKET              = aws_s3_bucket.reports.id
      REPORT_PREFIX              = "executive-reports"
      BEDROCK_MODEL_ID           = var.bedrock_model_id
      ENABLE_BEDROCK             = "true"
      REPORT_PERIOD_HOURS        = tostring(var.report_period_hours)
      MAX_ITEMS_PER_TABLE        = tostring(var.max_report_items_per_table)
      ORGANIZATION_NAME          = var.organization_name
      REPORT_TITLE               = var.report_title
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.report_generator,
    aws_iam_role_policy_attachment.report_generator_basic,
    aws_iam_role_policy.report_generator,
  ]
}
