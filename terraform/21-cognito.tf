resource "aws_cognito_user_pool" "lab" {
  name           = "${local.name_prefix}-users"
  user_pool_tier = "ESSENTIALS"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 10
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  lambda_config {
    pre_token_generation_config {
      lambda_arn     = aws_lambda_function.pre_token.arn
      lambda_version = "V2_0"
    }
  }
}

resource "aws_cognito_resource_server" "api" {
  identifier   = local.resource_server_identifier
  name         = "${local.name_prefix}-api"
  user_pool_id = aws_cognito_user_pool.lab.id

  scope {
    scope_name        = "python.invoke"
    scope_description = "Invoke the Python API endpoint."
  }

  scope {
    scope_name        = "node.invoke"
    scope_description = "Invoke the Node.js API endpoint."
  }

  scope {
    scope_name        = "security.read"
    scope_description = "Read the security status endpoint and future incident centre API."
  }
}

resource "aws_cognito_user_pool_client" "lab" {
  name         = "${local.name_prefix}-client"
  user_pool_id = aws_cognito_user_pool.lab.id

  generate_secret               = false
  prevent_user_existence_errors = "ENABLED"

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile",
    local.python_scope,
    local.node_scope,
    local.security_scope,
  ]
  callback_urls                = ["https://localhost"]
  logout_urls                  = ["https://localhost"]
  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 1

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  auth_session_validity = 3

  depends_on = [aws_cognito_resource_server.api]
}

resource "aws_cognito_user_group" "students" {
  name         = "students"
  description  = "Students can invoke the Python endpoint."
  precedence   = 30
  user_pool_id = aws_cognito_user_pool.lab.id
}

resource "aws_cognito_user_group" "admins" {
  name         = "admins"
  description  = "Administrators can invoke the Python and Node.js endpoints."
  precedence   = 20
  user_pool_id = aws_cognito_user_pool.lab.id
}

resource "aws_cognito_user_group" "security" {
  name         = "security"
  description  = "Security users can invoke all endpoints, including the future incident centre boundary."
  precedence   = 10
  user_pool_id = aws_cognito_user_pool.lab.id
}

resource "aws_lambda_permission" "cognito_pre_token" {
  statement_id  = "AllowCognitoPreTokenInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_token.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.lab.arn
}
