locals {
  alerts_topic_arn = data.terraform_remote_state.network.outputs.alerts_topic_arn
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name}-unhealthy-hosts"
  alarm_description   = "At least one orders-api container is failing its health check"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = [local.alerts_topic_arn]
  ok_actions    = [local.alerts_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "${local.name}-http-5xx"
  alarm_description   = "More than 5 server errors in a minute (app errors plus load balancer 502/503/504)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "total"
    expression  = "FILL(app, 0) + FILL(elb, 0)"
    label       = "All 5xx"
    return_data = true
  }

  metric_query {
    id = "app"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
        TargetGroup  = aws_lb_target_group.app.arn_suffix
      }
    }
  }

  metric_query {
    id = "elb"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }

  alarm_actions = [local.alerts_topic_arn]
  ok_actions    = [local.alerts_topic_arn]
}
