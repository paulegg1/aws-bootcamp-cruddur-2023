resource "aws_lb" "cruddur-alb" {
  name     = "cruddur-alb"
  internal = false

  security_groups = [
    #data.aws_security_group.crud-srv-sg.id
    aws_security_group.allow_internet.id
  ]

  subnets = [
    aws_subnet.public_subnets[0].id,
    aws_subnet.public_subnets[1].id,
    aws_subnet.public_subnets[2].id,
    aws_subnet.public_subnets[3].id
  ]

  tags = {
    Name = "cruddur-alb"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}


## refer to crud-srv-sg
data "aws_security_group" "crud-srv-sg" {
    id = "sg-0ebb829b7bd863560"
}


resource "aws_lb_target_group" "cruddur-alb-be-tg" {
  health_check {
    interval            = 10
    path                = "/api/health-check"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  name        = "cruddur-alb-be-tg"
  port        = 4567
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_target_group" "cruddur-alb-fe-tg" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }

  name        = "cruddur-alb-fe-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}
#resource "aws_lb_target_group_attachment" "cruddur-alb-be-tg-att" {
#  target_group_arn = aws_lb_target_group.cruddur-alb-be-tg.arn
#  target_id        = aws_instance.test.id
#  port             = 4567
#}
#resource "aws_lb_target_group_attachment" "cruddur-alb-fe-tg-att" {
#  target_group_arn = aws_lb_target_group.cruddur-alb-fe-tg.arn
#  target_id        = aws_instance.test.id
#  port             = 3000
#}

resource "aws_lb_listener" "cruddur-alb-listner-4567" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = 4567
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cruddur-alb-be-tg.arn
  }
}

resource "aws_lb_listener" "cruddur-alb-listner-3000" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cruddur-alb-fe-tg.arn
  }
}

resource "aws_lb_listener" "cruddur-alb-listner-80" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "cruddur-alb-listner-443" {
  load_balancer_arn = aws_lb.cruddur-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "arn:aws:acm:us-east-1:540771840545:certificate/b5db34a2-025e-4a4f-a434-27017ec4346a"
  ssl_policy   = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cruddur-alb-fe-tg.arn
  }
}


resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.cruddur-alb-listner-443.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cruddur-alb-be-tg.arn
  }

  condition {
    host_header {
      values = ["api.cruddur.paulegg.com"]
    }
  }
}

resource "aws_security_group" "allow_internet" {
  name        = "cruddur-alb-sg"
  description = "Allow internet HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from Any"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["1.2.3.4/0"]
  }

  ingress {
    description      = "HTTPS from Any"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["1.2.3.4/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_internet"
  }
}
