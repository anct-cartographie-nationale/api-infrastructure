data "aws_s3_object" "openapi_file" {
  bucket = aws_s3_bucket.api.id
  key    = "v0/openapi.json"
}

locals {
  openapi_file = jsondecode(data.aws_s3_object.openapi_file.body)
  api_routes = flatten([
    for path, routes in local.openapi_file.paths : [
      for httpVerb, route in routes : {
        path                = trimprefix(path, "/")
        httpVerb            = httpVerb
        description         = route.summary
        operationId         = route.operationId
        apiKeyAuthorization = contains(route.security, { ApiKeyAuthorization = [] })
      }
    ]
  ])
}
