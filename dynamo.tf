resource "aws_dynamodb_table" "lieux_inclusion_numerique_table" {
  name           = "LieuxInclusionNumerique"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.tags
}

resource "aws_iam_role" "autoscaling_role" {
  name = "dynamodb-autoscaling-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_appautoscaling_target" "dynamodb_read_target" {
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  resource_id        = "table/${aws_dynamodb_table.lieux_inclusion_numerique_table.name}"
  min_capacity       = 1
  max_capacity       = 10
  role_arn           = aws_iam_role.autoscaling_role.arn
}

resource "aws_appautoscaling_target" "dynamodb_write_target" {
  service_namespace  = "dynamodb"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  resource_id        = "table/${aws_dynamodb_table.lieux_inclusion_numerique_table.name}"
  min_capacity       = 1
  max_capacity       = 10
  role_arn           = aws_iam_role.autoscaling_role.arn
}

resource "aws_appautoscaling_policy" "dynamodb_read_policy" {
  name               = "dynamodb-scaling-read-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    disable_scale_in   = false
  }
}

resource "aws_appautoscaling_policy" "dynamodb_write_policy" {
  name               = "dynamodb-scaling-write-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_write_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value       = 70.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    disable_scale_in   = false
  }
}

resource "aws_iam_policy" "lieux_inclusion_numerique_table_policy" {
  name        = "lieux_inclusion_numerique_table_policy"
  description = "IAM policy to allow DynamoDB Table Lieux d'inclusion numérique access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Resource = aws_dynamodb_table.lieux_inclusion_numerique_table.arn
        Effect   = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
      }
    ]
  })
}
