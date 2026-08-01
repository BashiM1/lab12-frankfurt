##############################################################
# WAF Web ACL
##############################################################

resource "aws_wafv2_web_acl" "api_acl" {

  name = "api-waf"

  scope = "REGIONAL"

  default_action {

    allow {}

  }

  visibility_config {

    cloudwatch_metrics_enabled = true

    metric_name = "api-waf"

    sampled_requests_enabled = true

  }

  ##########################################################

  rule {

    name = "AWSManagedCommonRules"

    priority = 1

    override_action {

      none {}

    }

    statement {

      managed_rule_group_statement {

        vendor_name = "AWS"

        name = "AWSManagedRulesCommonRuleSet"

      }

    }

    visibility_config {

      cloudwatch_metrics_enabled = true

      metric_name = "CommonRules"

      sampled_requests_enabled = true

    }

  }

}

##############################################################
# WAF Logging
##############################################################

resource "aws_wafv2_web_acl_logging_configuration" "logging" {

  log_destination_configs = [

    aws_cloudwatch_log_group.waf_logs.arn

  ]

  resource_arn = aws_wafv2_web_acl.api_acl.arn

}
