resource "aws_vpc" "this" {
   cidr_block = var.vpc_cidr 
   tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_subnet" "private_app"{
    vpc_id = aws_vpc.this.id
    cidr_block = var.private_app_subnet_cidr
    availability_zone = "us-east-2a"

    tags = {
        Name = "${var.project_name}-private-subnet-app"
    }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnet_cidr
  availability_zone = "us-east-2b"

  tags = {
    Name = "${var.project_name}-private-subnet-db"
  }
}

resource "aws_subnet" "private_db_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnet_2_cidr
  availability_zone = "us-east-2c"

  tags = {
    Name = "${var.project_name}-private-subnet-db-2"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}