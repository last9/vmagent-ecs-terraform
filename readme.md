# Terraform Module for Levitate Installation using AWS ECS with EFS and Environment Configurations

## Overview

This Terraform module is designed to deploy a Docker container as an AWS ECS Fargate task with an attached Amazon EFS filesystem. It allows for customized configurations, including setting up environment variables and remote write credentials for Levitate.

## Prerequisites

- Terraform v0.12+ installed.
- AWS CLI installed and configured.
- An AWS account with necessary permissions.

## Features

- **ECS Fargate Task**: Deploys a Docker container on AWS ECS Fargate.
- **EFS Filesystem**: Attaches an EFS filesystem to the ECS task for persistent storage.
- **Customizable Security Groups**: Configures security groups for ECS tasks and EFS communication.
- **Environment Configurations**: Sets up environment variables and remote write credentials.

## Input Variables

- `aws_region`: The AWS region for deploying resources.
- `vpc_id`: The ID of the VPC where resources will be created.
- `subnet_ids`: List of subnet IDs for the ECS service and EFS mount targets.
- `ecs_cluster_id`: The ID of the ECS cluster for deploying services.
- `levitate_remote_write_url`: The URL for Levitate remote write.
- `levitate_remote_write_username`: The username for Levitate remote write authentication.
- `levitate_remote_write_password`: The password for Levitate remote write authentication.
- `environment`: The environment name where all these resources will reside.
- `container_mount_path`: The path where the container will mount the volume.

## Usage

To use this module in your Terraform environment, include the following configuration:

```hcl
module "vmagent" {
  source                         = "./path/to/your/module"
  aws_region                     = "ap-south-1"
  vpc_id                         = "vpc-xxxxxxxxxxxx"
  subnet_ids                     = ["subnet-yyyyyyyy", "subnet-zzzzzzzz"]
  ecs_cluster_id                 = "ecs-cluster-id"
  levitate_remote_write_url      = "https://app-tsdb.last9.io/write"
  levitate_remote_write_username = "username"
  levitate_remote_write_password = "password"
  container_mount_path           = "/efs/mnt"
  environment                    = "staging"
}
```

Replace the values with your specific configuration details.

## Outputs

- `ecs_service_name`: The name of the ECS service deployed.
- Additional outputs can be added as per the module configuration.

## Notes

- Ensure that the provided AWS credentials have the necessary permissions for creating and managing ECS and EFS resources.
- Review and adjust security group rules as per your organization's security policies.
- Validate your Terraform configurations with `terraform plan` before applying changes with `terraform apply`.

### How to mount/unmount configuration files to the created EFS
- Refer [efs_mount.md](efs_mount.md)
- Refer [efs_unmount.md](efs_unmount.md)
