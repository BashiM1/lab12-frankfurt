locals {
  name_prefix = var.project_name

  resource_server_identifier = "${local.name_prefix}-api"

  python_scope   = "${local.resource_server_identifier}/python.invoke"
  node_scope     = "${local.resource_server_identifier}/node.invoke"
  security_scope = "${local.resource_server_identifier}/security.read"

  bedrock_model_id = var.bedrock_model_id

  bedrock_inference_profile_arn = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${local.bedrock_model_id}"

  bedrock_foundation_model_arns = [
    for region in [
      "eu-central-1",
      "eu-north-1",
      "eu-south-1",
      "eu-south-2",
      "eu-west-1",
      "eu-west-3",
    ] : "arn:aws:bedrock:${region}::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
  ]

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Security training lab"
    },
    var.additional_tags
  )
}
