output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "app_url" {
  value = "http://${aws_lb.main.dns_name}/api/orders"
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.orders_api.name
}
