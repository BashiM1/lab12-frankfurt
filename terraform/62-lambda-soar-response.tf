data "archive_file" "soar_response" {
  type        = "zip"
  source_file = "${path.module}/src/soar-response/lambda_function.py"
  output_path = "${path.module}/soar-response.zip"
}

resource "aws_lambda_function" "soar_response" {
  function_name    = "${local.name_prefix}-soar-response"
  role             = aws_iam_role.soar_response.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.soar_response.output_path
  source_code_hash = data.archive_file.soar_response.output_base64sha256
  timeout          = 120
  memory_size      = 512

  environment {
    variables = {
      CORRELATION_FINDINGS_TABLE = aws_dynamodb_table.waf_correlation_findings.name
      SECURITY_INCIDENTS_TABLE   = aws_dynamodb_table.security_incidents.name
      SNS_TOPIC_ARN              = aws_sns_topic.security_alerts.arn
      BEDROCK_MODEL_ID           = var.bedrock_model_id
      ENABLE_BEDROCK             = "true"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.soar_response,
    aws_iam_role_policy_attachment.soar_response_basic,
    aws_iam_role_policy.soar_response,
  ]
}
