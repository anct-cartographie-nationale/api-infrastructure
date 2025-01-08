data "aws_s3_object" "import_from_s3_archive" {
  count  = fileexists("${path.module}/import-from-s3/index.mjs") ? 0 : 1
  bucket = aws_s3_bucket.api.id
  key    = "utilities/import-from-s3.zip"
}

data "archive_file" "import_from_s3_archive" {
  count       = fileexists("${path.module}/import-from-s3/index.mjs") ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/import-from-s3"
  output_path = "${path.module}/import-from-s3.zip"
}

resource "aws_lambda_function" "import_from_s3" {
  filename         = fileexists("${path.module}/import-from-s3/index.mjs") ? "import-from-s3.zip" : null
  s3_bucket        = fileexists("${path.module}/import-from-s3/index.mjs") ? null : aws_s3_bucket.api.id
  s3_key           = fileexists("${path.module}/import-from-s3/index.mjs") ? null : "utilities/import-from-s3.zip"
  function_name    = "import-from-s3"
  role             = aws_iam_role.import_from_s3_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  memory_size      = 1024
  timeout          = 900
  source_code_hash = fileexists("${path.module}/import-from-s3/index.mjs") ? data.archive_file.import_from_s3_archive[0].output_base64sha256 : null
}

resource "aws_cloudwatch_log_group" "import_from_s3_cloudwatch_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.import_from_s3.function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "import_from_s3_cloudwatch_role_policy" {
  name   = "${local.name_prefix}.import-from-s3.cloud-watch-role-policy"
  role   = aws_iam_role.import_from_s3_execution_role.id
  policy = data.aws_iam_policy_document.cloud_watch_role_policy_document.json
}


data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "import_from_s3_execution_role" {
  name               = "import-from-s3-lambda-role"
  description        = "References a policy document that can assume role for import from s3 lambda trigger"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_policy.json
}
