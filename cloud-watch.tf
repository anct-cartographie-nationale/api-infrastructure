data "aws_iam_policy_document" "cloud_watch_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "cloud_watch_role_policy" {
  name   = "${local.name_prefix}.cloud-watch-role-policy"
  role   = aws_iam_role.api_keys_authorizer_execution_role.id
  policy = data.aws_iam_policy_document.cloud_watch_role_policy_document.json
}
