data "archive_file" "waf_correlation" {
  type        = "zip"
  source_file = "${path.module}/src/waf-correlation/lambda_function.py"
  output_path = "${path.module}/waf-correlation.zip"
}

resource "aws_lambda_function" "waf_correlation" {
  function_name    = "${local.name_prefix}-waf-correlation"
  role             = aws_iam_role.waf_correlation.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.waf_correlation.output_path
  source_code_hash = data.archive_file.waf_correlation.output_base64sha256
  timeout          = 120
  memory_size      = 512

  environment {
    variables = {
      WAF_EVENTS_TABLE           = aws_dynamodb_table.waf_events.name
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      BEDROCK_MODEL_ID           = var.bedrock_model_id
      CORRELATION_WINDOW_MINUTES = tostring(var.correlation_window_minutes)
      MINIMUM_EVENT_COUNT        = tostring(var.minimum_event_count)
      MAX_EVENTS                 = tostring(var.max_correlation_events)
      ADMIN_URI_KEYWORDS         = "admin,login,signin,auth,token,cognito,security"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.waf_correlation,
    aws_iam_role_policy_attachment.waf_correlation_basic,
    aws_iam_role_policy.waf_correlation,
  ]
}
