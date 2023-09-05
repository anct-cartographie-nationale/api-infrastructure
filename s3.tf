resource "aws_s3_bucket" "api" {
  bucket        = replace("${local.product_information.context.project}_${local.product_information.context.service}", "_", "-")
  force_destroy = true
  tags          = local.tags
}
