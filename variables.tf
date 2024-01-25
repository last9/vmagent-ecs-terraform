variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service and EFS mount targets"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ECS Cluster ID"
  type        = string
}

variable "environment" {
  description = "Environment in which these resources will reside"
  type        = string
}

variable "levitate_remote_write_url" {
  description = "URL for Levitate remote write"
  type        = string
}

variable "levitate_remote_write_username" {
  description = "Username for Levitate remote write"
  type        = string
}

variable "levitate_remote_write_password" {
  description = "Password for Levitate remote write"
  type        = string
}

variable "container_mount_path" {
  description = "The path where the container will mount the volume"
  type        = string
}
