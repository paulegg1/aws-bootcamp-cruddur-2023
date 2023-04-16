resource "aws_db_instance" "postgres" {
  identifier                            = "cruddur-db-instance"
  instance_class                        = "db.t3.micro"
  engine                                = "postgres"
  engine_version                        = 14.6
  username                              = "root"
  password                              = "huEE33z2Qvl383"
  allocated_storage                     = 20
  availability_zone                     = "us-east-1a"
  backup_retention_period               = 0
  port                                  = 5432
  db_subnet_group_name                  = aws_db_subnet_group.cruddur_dbsn_group.name
  db_name                               = "cruddur"
  storage_type                          = "gp2"
  publicly_accessible                   = true
  storage_encrypted                     = true
  performance_insights_retention_period = 7
  performance_insights_enabled          = true
  deletion_protection                   = false
  skip_final_snapshot                   = true
  vpc_security_group_ids = [ aws_security_group.allow_postgres.id ]
}


resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow postgres inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "postgres from GP"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["34.78.33.243/32"]
  }

  ingress {
    description      = "CruddurECS"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = ["sg-08e0ef94ae963f863"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_postgres"
  }
}
/*
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password huEE33z2Qvl383 \
  --allocated-storage 20 \
  --availability-zone ca-central-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
  */