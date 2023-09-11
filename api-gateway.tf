resource "aws_apigatewayv2_api" "cartographie_nationale" {
  name          = "${local.product_information.context.project}-${local.product_information.context.service}"
  tags          = local.tags
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      "*"
    ]
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

resource "aws_apigatewayv2_integration" "api_integrations" {
  for_each = {
    for object in data.aws_s3_object.s3_objects :
    object.key => object
    if object.content_type == "application/zip"
  }

  api_id             = aws_apigatewayv2_api.cartographie_nationale.id
  integration_uri    = aws_lambda_function.api_routes[each.key].invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_route" {
  for_each = {
    for object in data.aws_s3_object.s3_objects :
    object.key => object
    if object.content_type == "application/zip"
  }

  api_id    = aws_apigatewayv2_api.cartographie_nationale.id
  route_key = "GET /${aws_lambda_function.api_routes[each.key].function_name}"
  target    = "integrations/${aws_apigatewayv2_integration.api_integrations[each.key].id}"
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
