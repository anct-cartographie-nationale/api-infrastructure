resource "aws_dynamodb_table" "api_keys_table" {
  name         = "${local.product_information.context.project}.api-keys"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }

  tags = local.tags
}

data "aws_iam_policy_document" "api_keys_table_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.api_keys_table.arn]
  }
}

resource "aws_iam_policy" "api_keys_table_policy" {
  name        = "${local.name_prefix}.keys-table-policy"
  description = "IAM policy to allow DynamoDB Table api-keys access"
  policy      = data.aws_iam_policy_document.api_keys_table_policy_document.json
}

data "aws_s3_object" "api_keys_authorizer_archive" {
  count  = fileexists("${path.module}/api-keys-authorizer/index.mjs") ? 0 : 1
  bucket = aws_s3_bucket.api.id
  key    = "utilities/api-keys-authorizer.zip"
}

data "archive_file" "api_keys_authorizer_archive" {
  count       = fileexists("${path.module}/api-keys-authorizer/index.mjs") ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/api-keys-authorizer"
  output_path = "${path.module}/api-keys-authorizer.zip"
}

resource "aws_lambda_function" "api_keys_authorizer" {
  filename         = fileexists("${path.module}/api-keys-authorizer/index.mjs") ? "api-keys-authorizer.zip" : null
  s3_bucket        = fileexists("${path.module}/api-keys-authorizer/index.mjs") ? null : aws_s3_bucket.api.id
  s3_key           = fileexists("${path.module}/api-keys-authorizer/index.mjs") ? null : "utilities/api-keys-authorizer.zip"
  function_name    = "api-keys-authorizer"
  role             = aws_iam_role.api_keys_authorizer_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = fileexists("${path.module}/api-keys-authorizer/index.mjs") ? data.archive_file.import_from_s3_archive[0].output_base64sha256 : null
}

resource "aws_cloudwatch_log_group" "api_keys_authorizer_cloudwatch_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.api_keys_authorizer.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "api_keys_authorizer_cloudwatch_role_policy" {
  name   = "${local.name_prefix}.api-keys-authorizer.cloud-watch-role-policy"
  role   = aws_iam_role.api_keys_authorizer_execution_role.id
  policy = data.aws_iam_policy_document.cloud_watch_role_policy_document.json
}

data "aws_iam_policy_document" "api_keys_authorizer_execution_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "api_keys_authorizer_execution_role" {
  name               = "${local.name_prefix}.keys-authorizer-execution-role"
  description        = "Authentication iam role references a policy document that can assume role for lambda authorizer"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.api_keys_authorizer_execution_policy.json
}

resource "aws_iam_role_policy" "api_keys_table_role_policy" {
  name   = "${local.name_prefix}.keys-table-role-policy"
  role   = aws_iam_role.api_keys_authorizer_execution_role.id
  policy = data.aws_iam_policy_document.api_keys_table_policy_document.json
}
