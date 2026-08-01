data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${local.name_prefix}-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "security_api" {
  name               = "${local.name_prefix}-security-status-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "pre_token" {
  name               = "${local.name_prefix}-token-scope-control-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "unused_token_detector" {
  name               = "${local.name_prefix}-unused-token-detector-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "waf_analyzer" {
  name               = "${local.name_prefix}-waf-analyzer-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

locals {
  basic_lambda_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "api_basic" {
  role       = aws_iam_role.api.name
  policy_arn = local.basic_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "security_api_basic" {
  role       = aws_iam_role.security_api.name
  policy_arn = local.basic_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "pre_token_basic" {
  role       = aws_iam_role.pre_token.name
  policy_arn = local.basic_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "unused_token_detector_basic" {
  role       = aws_iam_role.unused_token_detector.name
  policy_arn = local.basic_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "waf_analyzer_basic" {
  role       = aws_iam_role.waf_analyzer.name
  policy_arn = local.basic_lambda_policy_arn
}

data "aws_iam_policy_document" "api_data" {
  statement {
    sid       = "MarkTrackedTokensUsed"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.token_tracking.arn]
  }
}

resource "aws_iam_role_policy" "api_data" {
  name   = "token-tracking-update"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api_data.json
}

data "aws_iam_policy_document" "security_api_data" {
  statement {
    sid       = "MarkTrackedTokensUsed"
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.token_tracking.arn]
  }
}

resource "aws_iam_role_policy" "security_api_data" {
  name   = "token-tracking-update"
  role   = aws_iam_role.security_api.id
  policy = data.aws_iam_policy_document.security_api_data.json
}

data "aws_iam_policy_document" "unused_token_detector" {
  statement {
    sid    = "ReadAndUpdateTokenTracking"
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
    ]
    resources = [aws_dynamodb_table.token_tracking.arn]
  }

  statement {
    sid     = "InvokeBedrockModel"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = concat(
      [local.bedrock_inference_profile_arn],
      local.bedrock_foundation_model_arns,
    )
  }

  statement {
    sid       = "PublishSecurityAlert"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]
  }
}

resource "aws_iam_role_policy" "unused_token_detector" {
  name   = "unused-token-detection"
  role   = aws_iam_role.unused_token_detector.id
  policy = data.aws_iam_policy_document.unused_token_detector.json
}

data "aws_iam_policy_document" "waf_analyzer" {
  statement {
    sid     = "ReadWafLogEvents"
    effect  = "Allow"
    actions = ["logs:FilterLogEvents"]
    resources = [
      aws_cloudwatch_log_group.waf.arn,
      "${aws_cloudwatch_log_group.waf.arn}:*",
    ]
  }

  statement {
    sid       = "StoreNormalizedWafEvents"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.waf_events.arn]
  }

  statement {
    sid     = "InvokeBedrockModel"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = concat(
      [local.bedrock_inference_profile_arn],
      local.bedrock_foundation_model_arns,
    )
  }
}

resource "aws_iam_role_policy" "waf_analyzer" {
  name   = "waf-log-analysis"
  role   = aws_iam_role.waf_analyzer.id
  policy = data.aws_iam_policy_document.waf_analyzer.json
}
