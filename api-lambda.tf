data "aws_s3_objects" "s3_objects_metadata" {
  bucket = aws_s3_bucket.api.id
  prefix = "v0/"
}

data "aws_s3_object" "s3_objects" {
  count  = length(data.aws_s3_objects.s3_objects_metadata.keys)
  key    = element(data.aws_s3_objects.s3_objects_metadata.keys, count.index)
  bucket = data.aws_s3_objects.s3_objects_metadata.id
}

locals {
  s3_objects_map = {
    for obj in data.aws_s3_object.s3_objects :
    obj.key => obj
  }
}

resource "aws_lambda_function" "api_routes" {
  for_each = { for route in local.api_routes : route.key => route }

  function_name    = each.key
  s3_bucket        = aws_s3_bucket.api.id
  s3_key           = "v0/${each.value.operationId}.zip"
  runtime          = "nodejs18.x"
  handler          = "index.handler"
  timeout          = 20
  memory_size      = 2048
  role             = aws_iam_role.api_route_execution_role.arn
  source_code_hash = local.s3_objects_map["v0/${each.value.operationId}.zip"].etag
  description      = each.value.description
}

resource "aws_cloudwatch_log_group" "api_routes_log_group" {
  for_each = aws_lambda_function.api_routes

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "api_route_role_policy" {
  name   = "${local.name_prefix}.api-routes.cloud-watch-role-policy"
  role   = aws_iam_role.api_route_execution_role.id
  policy = data.aws_iam_policy_document.cloud_watch_role_policy_document.json
}

data "aws_iam_policy_document" "api_route_execution_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "api_route_execution_role" {
  name               = "api-routes-role"
  description        = "References a policy document that can assume role for api route"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.api_route_execution_policy.json
}

resource "aws_iam_policy_attachment" "sources_table_policy_attachment" {
  name       = "sources_table_policy_attachment"
  policy_arn = aws_iam_policy.sources_table_policy.arn
  roles      = [aws_iam_role.api_route_execution_role.name]
}

resource "aws_iam_policy_attachment" "lieux_inclusion_numerique_table_policy_attachment" {
  name       = "lieux_inclusion_numerique_table_policy_attachment"
  policy_arn = aws_iam_policy.lieux_inclusion_numerique_table_policy.arn
  roles      = [aws_iam_role.api_route_execution_role.name]
}
