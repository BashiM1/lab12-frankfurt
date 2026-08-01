data "archive_file" "unused_token_detector" {
  type        = "zip"
  source_file = "${path.module}/src/unused-token-detector/lambda_function.py"
  output_path = "${path.module}/unused-token-detector.zip"
}

resource "aws_lambda_function" "unused_token_detector" {
  function_name    = "${local.name_prefix}-unused-token-detector"
  role             = aws_iam_role.unused_token_detector.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.unused_token_detector.output_path
  source_code_hash = data.archive_file.unused_token_detector.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.token_tracking.name
      ALERT_TOPIC_ARN      = aws_sns_topic.security_alerts.arn
      BEDROCK_MODEL_ID     = local.bedrock_model_id
      UNUSED_TOKEN_MINUTES = tostring(var.unused_token_minutes)
      MAX_SCAN_ITEMS       = "250"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.unused_token_detector,
    aws_iam_role_policy_attachment.unused_token_detector_basic,
    aws_iam_role_policy.unused_token_detector,
  ]
}

