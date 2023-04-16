provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "cruddur-terraform"
    key    = "vpc-terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}



resource "aws_vpc" "main" {
  cidr_block = "10.6.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "us-east-vpc-01"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = var.public_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "${element(var.cidr16array, 0)}.${element(var.cidr16array, 1)}.${(count.index % 4 * 8) + (floor(count.index /4))}.${element(var.cidr16array, 3)}/24"
  availability_zone = data.aws_availability_zones.available.names[count.index % 4]
  tags = {
    Name = "us-east-vpc-01-pubsn01-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "${element(var.cidr16array, 0)}.${element(var.cidr16array, 1)}.${(count.index % 4 * 8) + (floor(count.index /4)) + 32}.${element(var.cidr16array, 3)}/24"
  availability_zone = data.aws_availability_zones.available.names[count.index % 4]
  tags = {
    Name = "us-east-vpc-01-prvsn01-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "East US1 Main VPC IGW"
 }
}

resource "aws_route_table" "public_internet_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "IGW out RT"
 }
}

resource "aws_route_table_association" "public_subnet_assoc" {
 count = var.public_subnet_count
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.public_internet_rt.id
}

resource "aws_db_subnet_group" "cruddur_dbsn_group" {
  name       = "cruddur_dbsn_group"
  subnet_ids = aws_subnet.public_subnets[*].id

  tags = {
    Name = "cruddur_dbsn_group"
  }
}




