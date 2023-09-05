resource "aws_apigatewayv2_api" "cartographie_nationale" {
  name          = "${local.product_information.context.project}-${local.product_information.context.service}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "cartographie_nationale" {
  api_id = aws_apigatewayv2_api.cartographie_nationale.id

  name        = "production"
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

#resource "aws_apigatewayv2_integration" "hello_world" {
#  api_id = aws_apigatewayv2_api.cartographie_nationale.id
#
#  integration_uri    = aws_lambda_function.hello_world.invoke_arn
#  integration_type   = "AWS_PROXY"
#  integration_method = "POST"
#}

#resource "aws_apigatewayv2_route" "hello_world" {
#  api_id = aws_apigatewayv2_api.cartographie_nationale.id
#
#  route_key = "GET /hello"
#  target    = "integrations/${aws_apigatewayv2_integration.hello_world.id}"
#}

resource "aws_cloudwatch_log_group" "api_cartographie_nationale" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.cartographie_nationale.name}"

  retention_in_days = 30
}

#resource "aws_lambda_permission" "api_cartographie_nationale" {
#  statement_id  = "AllowExecutionFromAPIGateway"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.hello_world.function_name
#  principal     = "apigateway.amazonaws.com"
#
#  source_arn = "${aws_apigatewayv2_api.cartographie_nationale.execution_arn}/*/*"
#}
