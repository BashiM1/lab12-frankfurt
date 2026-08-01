resource "aws_iam_role" "waf_correlation" {
  name               = "${local.name_prefix}-waf-correlation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "soar_response" {
  name               = "${local.name_prefix}-soar-response-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "report_generator" {
  name               = "${local.name_prefix}-report-generator-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "waf_correlation_basic" {
  role       = aws_iam_role.waf_correlation.name
  policy_arn = local.basic_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "soar_response_basic" {
  role       = aws_iam_role.soar_response.name
  policy_arn = local.basic_lambda_policy_arn
}

resource "aws_iam_role_policy_attachment" "report_generator_basic" {
  role       = aws_iam_role.report_generator.name
  policy_arn = local.basic_lambda_policy_arn
}

data "aws_iam_policy_document" "waf_correlation" {
  statement {
    sid       = "ReadNormalizedWafEvents"
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.waf_events.arn]
  }

  statement {
    sid       = "WriteCorrelationFindings"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.waf_correlation_findings.arn]
  }

  statement {
    sid       = "PublishFindingEvents"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = ["*"]
  }

  statement {
    sid     = "InvokeBedrock"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = concat(
      [local.bedrock_inference_profile_arn],
      local.bedrock_foundation_model_arns,
    )
  }
}

resource "aws_iam_role_policy" "waf_correlation" {
  name   = "lab12-waf-correlation"
  role   = aws_iam_role.waf_correlation.id
  policy = data.aws_iam_policy_document.waf_correlation.json
}

data "aws_iam_policy_document" "soar_response" {
  statement {
    sid    = "ReadAndUpdateFinding"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]
    resources = [aws_dynamodb_table.waf_correlation_findings.arn]
  }

  statement {
    sid       = "CreateIncident"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.security_incidents.arn]
  }

  statement {
    sid       = "PublishAlert"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.security_alerts.arn]
  }

  statement {
    sid     = "InvokeBedrock"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = concat(
      [local.bedrock_inference_profile_arn],
      local.bedrock_foundation_model_arns,
    )
  }
}

resource "aws_iam_role_policy" "soar_response" {
  name   = "lab12a-soar-response"
  role   = aws_iam_role.soar_response.id
  policy = data.aws_iam_policy_document.soar_response.json
}

data "aws_iam_policy_document" "report_generator" {
  statement {
    sid     = "ReadSecurityTables"
    effect  = "Allow"
    actions = ["dynamodb:Scan"]
    resources = [
      aws_dynamodb_table.waf_events.arn,
      aws_dynamodb_table.waf_correlation_findings.arn,
      aws_dynamodb_table.security_incidents.arn,
    ]
  }

  statement {
    sid       = "WriteReports"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.reports.arn}/executive-reports/*"]
  }

  statement {
    sid     = "InvokeBedrock"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = concat(
      [local.bedrock_inference_profile_arn],
      local.bedrock_foundation_model_arns,
    )
  }
}

resource "aws_iam_role_policy" "report_generator" {
  name   = "lab12b-report-generator"
  role   = aws_iam_role.report_generator.id
  policy = data.aws_iam_policy_document.report_generator.json
}
