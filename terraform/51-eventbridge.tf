resource "aws_cloudwatch_event_rule" "unused_token_check" {
  name                = "${local.name_prefix}-unused-token-check"
  description         = "Checks for issued access tokens that were not used within the configured threshold."
  schedule_expression = var.unused_token_schedule
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "unused_token_detector" {
  rule = aws_cloudwatch_event_rule.unused_token_check.name
  arn  = aws_lambda_function.unused_token_detector.arn
}

resource "aws_lambda_permission" "eventbridge_unused_token_detector" {
  statement_id  = "AllowEventBridgeUnusedTokenCheck"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unused_token_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.unused_token_check.arn
}

