variable "aws_region" {
  description = "AWS region for the reconstruction lab. This environment is intentionally fixed to Frankfurt."
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = var.aws_region == "eu-central-1"
    error_message = "This reconstruction must be deployed in eu-central-1."
  }
}

variable "project_name" {
  description = "Short professional prefix used in resource names."
  type        = string
  default     = "lab12-frankfurt"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "project_name must be 3 to 25 lowercase letters, numbers, or hyphens and start with a letter."
  }
}

variable "environment" {
  description = "Environment label used in resource tags."
  type        = string
  default     = "lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,11}$", var.environment))
    error_message = "environment must be 2 to 12 lowercase letters, numbers, or hyphens."
  }
}

variable "bedrock_model_id" {
  description = "Enabled Anthropic Claude Bedrock inference profile available from eu-central-1."
  type        = string
  default     = "eu.anthropic.claude-haiku-4-5-20251001-v1:0"

  validation {
    condition = (
      length(trimspace(var.bedrock_model_id)) > 0
      && !startswith(trimspace(var.bedrock_model_id), "<")
    )
    error_message = "bedrock_model_id must contain a real model or inference profile ID, not a placeholder."
  }
}

variable "alert_email" {
  description = "Optional email address for SNS alerts. Leave null to create the topic without an email subscription."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.alert_email == null || can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.alert_email))
    error_message = "alert_email must be null or a valid email address."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for lab log groups."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30], var.log_retention_days)
    error_message = "log_retention_days must be one of 1, 3, 5, 7, 14, or 30."
  }
}

variable "unused_token_minutes" {
  description = "Age at which an unused tracked token becomes alertable."
  type        = number
  default     = 10

  validation {
    condition     = var.unused_token_minutes >= 1 && var.unused_token_minutes <= 60
    error_message = "unused_token_minutes must be between 1 and 60."
  }
}

variable "unused_token_schedule" {
  description = "EventBridge schedule for the unused-token detector."
  type        = string
  default     = "rate(5 minutes)"
}

variable "waf_lookback_minutes" {
  description = "CloudWatch Logs lookback window for the WAF analyzer."
  type        = number
  default     = 10

  validation {
    condition     = var.waf_lookback_minutes >= 1 && var.waf_lookback_minutes <= 60
    error_message = "waf_lookback_minutes must be between 1 and 60."
  }
}

variable "waf_max_log_events" {
  description = "Maximum WAF log events processed by one analyzer invocation."
  type        = number
  default     = 25

  validation {
    condition     = var.waf_max_log_events >= 1 && var.waf_max_log_events <= 100
    error_message = "waf_max_log_events must be between 1 and 100."
  }
}

variable "waf_rate_limit" {
  description = "Maximum requests from one IP address in the WAF five-minute evaluation window."
  type        = number
  default     = 100

  validation {
    condition     = var.waf_rate_limit >= 10
    error_message = "waf_rate_limit must be at least 10."
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to supported resources."
  type        = map(string)
  default     = {}
}

variable "correlation_window_minutes" {
  description = "Lookback window for the Lab 12 WAF correlation agent."
  type        = number
  default     = 60
}

variable "minimum_event_count" {
  description = "Minimum normalized WAF records required to create a finding."
  type        = number
  default     = 3
}

variable "max_correlation_events" {
  description = "Maximum WAF events evaluated in one correlation run."
  type        = number
  default     = 500
}

variable "report_period_hours" {
  description = "Default reporting period used by the Lab 12b report Lambda."
  type        = number
  default     = 24
}

variable "max_report_items_per_table" {
  description = "Maximum records read from each reporting table."
  type        = number
  default     = 5000
}

variable "organization_name" {
  description = "Organization label displayed in the executive report."
  type        = string
  default     = "Frankfurt Security Lab"
}

variable "report_title" {
  description = "Title displayed in the Lab 12b PDF and JSON report."
  type        = string
  default     = "Executive Security Report"
}
