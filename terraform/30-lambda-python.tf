data "archive_file" "python_api" {
  type        = "zip"
  source_file = "${path.module}/src/python-api/lambda_function.py"
  output_path = "${path.module}/python-api.zip"
}

resource "aws_lambda_function" "python_api" {
  function_name    = "${local.name_prefix}-python-api"
  role             = aws_iam_role.api.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.python_api.output_path
  source_code_hash = data.archive_file.python_api.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.token_tracking.name
      REQUIRED_GROUPS      = "students,admins,security"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.python_api,
    aws_iam_role_policy_attachment.api_basic,
    aws_iam_role_policy.api_data,
  ]
}

