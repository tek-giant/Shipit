resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}/orders-api"
  retention_in_days = 14
}
