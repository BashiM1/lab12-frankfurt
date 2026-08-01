##############################################################
# API Gateway - REST API
##############################################################

resource "aws_api_gateway_rest_api" "waf_api" {

  name        = "waf-bedrock-api"

  description = "REST API protected by AWS WAF"

  endpoint_configuration {

    types = ["REGIONAL"]

  }

}

##############################################################
# Resource
##############################################################

resource "aws_api_gateway_resource" "analyze" {

  rest_api_id = aws_api_gateway_rest_api.waf_api.id

  parent_id = aws_api_gateway_rest_api.waf_api.root_resource_id

  path_part = "analyze"

}

##############################################################
# POST Method
##############################################################

resource "aws_api_gateway_method" "post" {

  rest_api_id = aws_api_gateway_rest_api.waf_api.id

  resource_id = aws_api_gateway_resource.analyze.id

  http_method = "POST"

  authorization = "NONE"

}

##############################################################
# Lambda Integration
##############################################################

resource "aws_api_gateway_integration" "lambda" {

  rest_api_id = aws_api_gateway_rest_api.waf_api.id

  resource_id = aws_api_gateway_resource.analyze.id

  http_method = aws_api_gateway_method.post.http_method

  integration_http_method = "POST"

  type = "AWS_PROXY"

  uri = aws_lambda_function.waf_bedrock.invoke_arn

}

##############################################################
# Deployment
##############################################################

resource "aws_api_gateway_deployment" "deployment" {

  depends_on = [

    aws_api_gateway_integration.lambda

  ]

  rest_api_id = aws_api_gateway_rest_api.waf_api.id

}

##############################################################
# Stage
##############################################################

resource "aws_api_gateway_stage" "prod" {

  deployment_id = aws_api_gateway_deployment.deployment.id

  rest_api_id = aws_api_gateway_rest_api.waf_api.id

  stage_name = "prod"

}

##############################################################
# Lambda Permission
##############################################################

resource "aws_lambda_permission" "apigateway" {

  statement_id = "AllowExecutionFromAPIGateway"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.waf_bedrock.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.waf_api.execution_arn}/*/*"

}
