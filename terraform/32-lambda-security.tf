data "archive_file" "security_api" {
  type        = "zip"
  source_file = "${path.module}/src/security-api/lambda_function.py"
  output_path = "${path.module}/security-api.zip"
}

resource "aws_lambda_function" "security_api" {
  function_name    = "${local.name_prefix}-security-status"
  role             = aws_iam_role.security_api.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.security_api.output_path
  source_code_hash = data.archive_file.security_api.output_base64sha256
  timeout          = 5
  memory_size      = 128

  environment {
    variables = {
      REQUIRED_GROUP       = "security"
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.token_tracking.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.security_api,
    aws_iam_role_policy_attachment.security_api_basic,
    aws_iam_role_policy.security_api_data,
  ]
}
