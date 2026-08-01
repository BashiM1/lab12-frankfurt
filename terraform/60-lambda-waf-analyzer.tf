data "archive_file" "waf_analyzer" {
  type        = "zip"
  source_file = "${path.module}/src/waf-analyzer/lambda_function.py"
  output_path = "${path.module}/waf-analyzer.zip"
}

resource "aws_lambda_function" "waf_analyzer" {
  function_name    = "${local.name_prefix}-waf-analyzer"
  role             = aws_iam_role.waf_analyzer.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.waf_analyzer.output_path
  source_code_hash = data.archive_file.waf_analyzer.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      WAF_LOG_GROUP    = aws_cloudwatch_log_group.waf.name
      DYNAMODB_TABLE   = aws_dynamodb_table.waf_events.name
      BEDROCK_MODEL_ID = local.bedrock_model_id
      LOOKBACK_MINUTES = tostring(var.waf_lookback_minutes)
      MAX_LOG_EVENTS   = tostring(var.waf_max_log_events)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.waf_analyzer,
    aws_iam_role_policy_attachment.waf_analyzer_basic,
    aws_iam_role_policy.waf_analyzer,
  ]
}
