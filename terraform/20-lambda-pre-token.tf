data "archive_file" "pre_token" {
  type        = "zip"
  source_file = "${path.module}/src/pre-token/lambda_function.py"
  output_path = "${path.module}/pre-token.zip"
}

resource "aws_lambda_function" "pre_token" {
  function_name    = "${local.name_prefix}-token-scope-control"
  role             = aws_iam_role.pre_token.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.pre_token.output_path
  source_code_hash = data.archive_file.pre_token.output_base64sha256
  timeout          = 5
  memory_size      = 128

  environment {
    variables = {
      RESOURCE_SERVER_IDENTIFIER = local.resource_server_identifier
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.pre_token,
    aws_iam_role_policy_attachment.pre_token_basic,
  ]
}

