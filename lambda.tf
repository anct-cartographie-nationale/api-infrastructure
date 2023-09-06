data "aws_s3_objects" "s3_objects_metadata" {
  bucket = aws_s3_bucket.api.id
  prefix = "v0/"
}

data "aws_s3_object" "s3_objects" {
  count  = length(data.aws_s3_objects.s3_objects_metadata.keys)
  key    = element(data.aws_s3_objects.s3_objects_metadata.keys, count.index)
  bucket = data.aws_s3_objects.s3_objects_metadata.id
}

resource "aws_lambda_function" "api_routes" {
  for_each = {
    for object in data.aws_s3_object.s3_objects :
    object.key => object
    if object.content_type == "application/zip"
  }

  function_name = replace(basename(each.key), "/\\..*/", "")

  s3_bucket = aws_s3_bucket.api.id
  s3_key    = each.key

  runtime = "nodejs18.x"
  handler = "index.handler"

  source_code_hash = each.value.etag

  role = aws_iam_role.api_routes_roles.arn
}

resource "aws_cloudwatch_log_group" "api_routes" {
  for_each = aws_lambda_function.api_routes

  name = "/aws/lambda/${each.value.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "api_routes_roles" {
  name = "api_routes_roles"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.api_routes_roles.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
