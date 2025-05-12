provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer"{
  key_name   = "deployer-key"
  public_key = file("/home/danan/.ssh/id_rsa.pub")
}

resource "aws_instance" "web" {
  ami                    = "ami-084568db4383264d4" # Ubuntu 20.04
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "TerraformWeb"
  }

  provisioner "local-exec" {
  command = "echo '[web]\n${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/danan/.ssh/id_rsa' > ../ansible/hosts.ini"
  }
}

output "instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

# Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.lb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "web-lb"
  }
}

# Target Group (untuk EC2 instances)
resource "aws_lb_target_group" "web_target_group" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = 30
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener untuk ALB
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      status_code = 200
      content_type = "text/plain"
      message_body = "Welcome to the Load Balancer"
    }
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "web-lb-sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "Subnets for ALB"
  type        = list(string)
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.web_lb.dns_name
}

