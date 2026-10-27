variable "alert_email" {
  description = "Email address that receives alarm notifications (set in terraform.tfvars, which Git ignores)"
  type        = string
}

resource "aws_sns_topic" "alerts" {
  name = "shipit-dev-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
