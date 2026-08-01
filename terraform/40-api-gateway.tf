resource "aws_api_gateway_rest_api" "lab" {
  name        = "${local.name_prefix}-api"
  description = "Serverless security lab API."

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.name_prefix}-cognito-authorizer"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.lab.id
  provider_arns   = [aws_cognito_user_pool.lab.arn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_resource" "python" {
  rest_api_id = aws_api_gateway_rest_api.lab.id
  parent_id   = aws_api_gateway_rest_api.lab.root_resource_id
  path_part   = "python"
}

resource "aws_api_gateway_resource" "node" {
  rest_api_id = aws_api_gateway_rest_api.lab.id
  parent_id   = aws_api_gateway_rest_api.lab.root_resource_id
  path_part   = "node"
}

resource "aws_api_gateway_resource" "security" {
  rest_api_id = aws_api_gateway_rest_api.lab.id
  parent_id   = aws_api_gateway_rest_api.lab.root_resource_id
  path_part   = "security"
}

resource "aws_api_gateway_resource" "security_status" {
  rest_api_id = aws_api_gateway_rest_api.lab.id
  parent_id   = aws_api_gateway_resource.security.id
  path_part   = "status"
}

resource "aws_api_gateway_method" "python_get" {
  rest_api_id          = aws_api_gateway_rest_api.lab.id
  resource_id          = aws_api_gateway_resource.python.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = [local.python_scope]
}

resource "aws_api_gateway_method" "node_get" {
  rest_api_id          = aws_api_gateway_rest_api.lab.id
  resource_id          = aws_api_gateway_resource.node.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = [local.node_scope]
}

resource "aws_api_gateway_method" "security_status_get" {
  rest_api_id          = aws_api_gateway_rest_api.lab.id
  resource_id          = aws_api_gateway_resource.security_status.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  authorization_scopes = [local.security_scope]
}

resource "aws_api_gateway_integration" "python" {
  rest_api_id             = aws_api_gateway_rest_api.lab.id
  resource_id             = aws_api_gateway_resource.python.id
  http_method             = aws_api_gateway_method.python_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.python_api.invoke_arn
}

resource "aws_api_gateway_integration" "node" {
  rest_api_id             = aws_api_gateway_rest_api.lab.id
  resource_id             = aws_api_gateway_resource.node.id
  http_method             = aws_api_gateway_method.node_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.node_api.invoke_arn
}

resource "aws_api_gateway_integration" "security_status" {
  rest_api_id             = aws_api_gateway_rest_api.lab.id
  resource_id             = aws_api_gateway_resource.security_status.id
  http_method             = aws_api_gateway_method.security_status_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.security_api.invoke_arn
}

resource "aws_api_gateway_deployment" "lab" {
  rest_api_id = aws_api_gateway_rest_api.lab.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.python.id,
      aws_api_gateway_resource.node.id,
      aws_api_gateway_resource.security.id,
      aws_api_gateway_resource.security_status.id,
      aws_api_gateway_method.python_get.id,
      aws_api_gateway_method.node_get.id,
      aws_api_gateway_method.security_status_get.id,
      aws_api_gateway_integration.python.id,
      aws_api_gateway_integration.node.id,
      aws_api_gateway_integration.security_status.id,
      aws_api_gateway_authorizer.cognito.id,
      local.python_scope,
      local.node_scope,
      local.security_scope,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.python,
    aws_api_gateway_integration.node,
    aws_api_gateway_integration.security_status,
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.lab.id
  deployment_id = aws_api_gateway_deployment.lab.id
  stage_name    = "prod"
}

resource "aws_lambda_permission" "api_python" {
  statement_id  = "AllowApiGatewayPython"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lab.execution_arn}/*/GET/python"
}

resource "aws_lambda_permission" "api_node" {
  statement_id  = "AllowApiGatewayNode"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lab.execution_arn}/*/GET/node"
}

resource "aws_lambda_permission" "api_security_status" {
  statement_id  = "AllowApiGatewaySecurityStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lab.execution_arn}/*/GET/security/status"
}

