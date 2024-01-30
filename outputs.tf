output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.last9-vmagent-service.name
}

# Add other outputs as necessary
