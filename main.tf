provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "aws_vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "vmagent_sg" {
  vpc_id = data.aws_vpc.aws_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vmagent-security-group"
  }
}

resource "aws_efs_file_system" "vmagent_efs" {
  creation_token = "vmagent-efs"

  tags = {
    Name = "VMagent EFS"
  }

}

resource "aws_security_group" "vmagent_efs_sg" {
  name        = "vmagent-efs-security-group"
  description = "Security group for EFS"
  vpc_id      = data.aws_vpc.aws_vpc.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this as needed for your environment
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EFS Security Group"
  }
}

resource "aws_efs_mount_target" "vmagent_efs_mt" {
  for_each        = toset(var.subnet_ids)
  file_system_id  = aws_efs_file_system.vmagent_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.vmagent_efs_sg.id]
}

resource "aws_security_group_rule" "ecs_to_efs" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vmagent_sg.id
  source_security_group_id = aws_security_group.vmagent_efs_sg.id
}

resource "aws_cloudwatch_log_group" "vmagent_ecs_log_group" {
  name = "/ecs/${var.environment}/vmagent"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy" "ecs_logging_policy" {
  name        = "ecs_logging_policy"
  description = "Policy for ECS tasks to allow logging to CloudWatch"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_logging_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_logging_policy.arn
}

resource "aws_iam_policy" "efs_access_policy" {
  name        = "efs-access-policy"
  description = "Policy for ECS tasks to access EFS"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeMountTargets"
        ],
        Resource = aws_efs_file_system.vmagent_efs.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_efs_attachment" {
  role       = aws_iam_role.ecs_execution_role.name  # Replace with your ECS execution role name
  policy_arn = aws_iam_policy.efs_access_policy.arn
}

resource "aws_ecs_service" "vmagent-service" {
  name            = "vmagent-ecs-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.vmagent_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.vmagent_sg.id]
    assign_public_ip = true # Check this and configure as required
  }

  tags = {
    Name        = "VMAgent"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "vmagent_task_definition" {
  family                   = "vmagent"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"  # adjust based on your application requirements
  memory                   = "4096"  # adjust based on your application requirements

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  volume {
    name = "vmagent-volume"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.vmagent_efs.id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
    }
  }

  container_definitions = jsonencode([
    {
      name      = "vmagent-scraper"
      image     = "victoriametrics/vmagent:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8429,
          hostPort      = 8429,
        }
      ]

      #      healthCheck = {
      #        command     = ["CMD-SHELL", "curl -f http://127.0.0.1:8429/health || exit 1"],
      #        interval    = 30,
      #        timeout     = 5,
      #        retries     = 3,
      #        startPeriod = 10
      #      }

      logConfiguration = {
        logDriver = "awslogs",
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.vmagent_ecs_log_group.name
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "-vmagent",
        }
      }

      command = [
        "--promscrape.config=/efs/mnt/vmagent-cfgs/vmagent.yaml",
        "--remoteWrite.url=${var.levitate_remote_write_url}",
        "--remoteWrite.basicAuth.username=${var.levitate_remote_write_username}",
        "--remoteWrite.basicAuth.password=${var.levitate_remote_write_password}"
      ]

      mountPoints = [
        {
          sourceVolume  = "vmagent-volume",
          containerPath = var.container_mount_path,
          readOnly      = false,
        }
      ]


      environment = [
        {
          name  = "ENVIRONMENT",
          value = var.environment,
        },
      ]
    }
  ])
}
