data "archive_file" "node_api" {
  type        = "zip"
  source_file = "${path.module}/src/node-api/index.js"
  output_path = "${path.module}/node-api.zip"
}

resource "aws_lambda_function" "node_api" {
  function_name    = "${local.name_prefix}-node-api"
  role             = aws_iam_role.api.arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = data.archive_file.node_api.output_path
  source_code_hash = data.archive_file.node_api.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      TOKEN_TRACKING_TABLE = aws_dynamodb_table.token_tracking.name
      REQUIRED_GROUPS      = "admins,security"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.node_api,
    aws_iam_role_policy_attachment.api_basic,
    aws_iam_role_policy.api_data,
  ]
}

