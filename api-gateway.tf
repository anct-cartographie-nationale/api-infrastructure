resource "aws_apigatewayv2_api" "cartographie_nationale" {
  name          = local.name_prefix
  tags          = local.tags
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["OPTIONS", "GET"]
    allow_headers  = ["Content-Type", "Authorization"]
    expose_headers = ["Content-Length"]
    max_age        = 3600
  }
}

resource "aws_apigatewayv2_stage" "cartographie_nationale" {
  name = "v0"
  tags = local.tags

  api_id      = aws_apigatewayv2_api.cartographie_nationale.id
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_cartographie_nationale.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

data "aws_iam_policy_document" "api_assume_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "authorizer_role" {
  name               = "authorizer-role"
  description        = "Authorizer iam role references a policy document that can assume role for api gateway"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.api_assume_role_policy_document.json
}

data "aws_iam_policy_document" "lambda_invoke_policy_document" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
    resources = [aws_lambda_function.api_keys_authorizer.arn]
    sid       = "ApiGatewayInvokeLambda"
  }
}

resource "aws_iam_policy" "authorizer_policy" {
  name        = "authorizer-policy"
  description = "IAM policy to allow authorizer lambda invocation form api gateway"
  policy      = data.aws_iam_policy_document.lambda_invoke_policy_document.json
}

resource "aws_iam_role_policy_attachment" "authorizer_role_policy_attachment" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = aws_iam_policy.authorizer_policy.arn
}

resource "aws_apigatewayv2_authorizer" "api_key_authorizer" {
  name                              = "${local.name_prefix}.key-authorizer"
  api_id                            = aws_apigatewayv2_api.cartographie_nationale.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.api_keys_authorizer.invoke_arn
  authorizer_credentials_arn        = aws_iam_role.authorizer_role.arn
  identity_sources                  = ["$request.header.x-api-key"]
  enable_simple_responses           = true
  authorizer_payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "api_integrations" {
  for_each = aws_lambda_function.api_routes

  api_id             = aws_apigatewayv2_api.cartographie_nationale.id
  integration_uri    = each.value.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_route" {
  for_each = { for route in local.api_routes : route.key => route }

  api_id             = aws_apigatewayv2_api.cartographie_nationale.id
  route_key          = "${upper(each.value.httpVerb)} ${each.value.path}"
  target             = "integrations/${aws_apigatewayv2_integration.api_integrations[each.key].id}"
  authorizer_id      = each.value.apiKeyAuthorization == true ? aws_apigatewayv2_authorizer.api_key_authorizer.id : null
  authorization_type = each.value.apiKeyAuthorization == true ? "CUSTOM" : null
}

resource "aws_cloudwatch_log_group" "api_cartographie_nationale" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.cartographie_nationale.name}"
  tags              = local.tags
  retention_in_days = 30
}

resource "aws_lambda_permission" "api_cartographie_nationale" {
  for_each = aws_lambda_function.api_routes

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.cartographie_nationale.execution_arn}/*/*"
}
