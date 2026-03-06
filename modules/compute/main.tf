data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix  = "${var.project}-${var.environment}"
  asg_subnets  = length(var.subnet_ids) > 0 ? var.subnet_ids : [var.subnet_id]
}

resource "aws_security_group" "main" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for ${local.name_prefix}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${local.name_prefix}-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Single EC2 instance (when use_asg = false)
resource "aws_instance" "main" {
  count         = var.use_asg ? 0 : 1
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "hostname: $(hostname)" > /tmp/instance-info.txt
    echo "environment: ${var.environment}" >> /tmp/instance-info.txt
    echo "project: ${var.project}" >> /tmp/instance-info.txt
  EOF
  )

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "${local.name_prefix}-instance"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Launch Template for ASG (when use_asg = true)
resource "aws_launch_template" "main" {
  count         = var.use_asg ? 1 : 0
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "hostname: $(hostname)" > /tmp/instance-info.txt
    echo "environment: ${var.environment}" >> /tmp/instance-info.txt
    echo "project: ${var.project}" >> /tmp/instance-info.txt
  EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${local.name_prefix}-instance"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "${local.name_prefix}-lt"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group (when use_asg = true)
resource "aws_autoscaling_group" "main" {
  count               = var.use_asg ? 1 : 0
  name                = "${local.name_prefix}-asg"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired
  vpc_zone_identifier = local.asg_subnets

  launch_template {
    id      = aws_launch_template.main[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
