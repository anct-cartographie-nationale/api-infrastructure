resource "aws_dynamodb_table" "lieux_inclusion_numerique_table" {
  name         = "LieuxInclusionNumerique"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.tags
}

resource "aws_s3_bucket" "dynamo_table_import" {
  bucket        = "${replace(local.product_information.context.project, "_", "-")}-dynamo-table-import"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_notification" "import_from_bucket_trigger_notification" {
  bucket = aws_s3_bucket.dynamo_table_import.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.import_from_s3.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}

resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.import_from_s3.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.dynamo_table_import.arn
}

data "aws_iam_policy_document" "read_from_s3_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = ["${aws_s3_bucket.dynamo_table_import.arn}/*"]
  }
}

resource "aws_iam_role_policy" "read_from_s3_role_policy" {
  name   = "read-from-s3-role-policy"
  role   = aws_iam_role.import_from_s3_role.id
  policy = data.aws_iam_policy_document.read_from_s3_policy_document.json
}

data "aws_iam_policy_document" "import_in_dynamo_table_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
    ]
    resources = [aws_dynamodb_table.lieux_inclusion_numerique_table.arn]
  }
}

resource "aws_iam_role_policy" "import_in_dynamo_table_role_policy" {
  name   = "import-in-dynamo-table-role-policy"
  role   = aws_iam_role.import_from_s3_role.id
  policy = data.aws_iam_policy_document.import_in_dynamo_table_policy_document.json
}

resource "aws_iam_policy" "lieux_inclusion_numerique_table_policy" {
  name        = "lieux-inclusion_numerique-table-policy"
  description = "IAM policy to allow DynamoDB Table Lieux d'inclusion numérique access"
  policy      = data.aws_iam_policy_document.import_in_dynamo_table_policy_document.json
}
