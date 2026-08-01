resource "aws_cloudwatch_event_rule" "waf_findings" {
  name        = "${local.name_prefix}-waf-findings"
  description = "Route notifiable WAF findings to the SOAR response Lambda."

  event_pattern = jsonencode({
    source      = ["seir.waf.correlation"]
    detail-type = ["WAF Threat Finding Created"]
    detail = {
      severity = ["MEDIUM", "HIGH", "CRITICAL"]
    }
  })
}

resource "aws_cloudwatch_event_target" "waf_findings_soar" {
  rule = aws_cloudwatch_event_rule.waf_findings.name
  arn  = aws_lambda_function.soar_response.arn
}

resource "aws_lambda_permission" "eventbridge_waf_findings_soar" {
  statement_id  = "AllowWafFindingInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.soar_response.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.waf_findings.arn
}
