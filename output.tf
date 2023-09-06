output "api_host_name" {
  description = "Host name for API Gateway."
  value       = regex("https://(.+?)/", aws_apigatewayv2_stage.cartographie_nationale.invoke_url).0
}

output "latest_stage_id" {
  description = "ID for API Gateway latest stage."
  value       = aws_apigatewayv2_stage.cartographie_nationale.id
}
