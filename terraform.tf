provider "aws" {
  region     = "ap-south-1"
  access_key = " "
  secret_key = " "
}
resource "aws_vpc" "flipkart" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "flipkart-vpc"
  }
}
##public subnet
resource "aws_subnet" "flipkart_public_subnet" {
  vpc_id                  = aws_vpc.flipkart.id
  cidr_block              = "10.0.0.0/25"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "flipkart_public_subnet"
  }
}


##public instance
resource "aws_instance" "flipkart_public" {
  ami                         = "ami-0f2ce9ce760bd7133"
  instance_type               = "t2.micro"
  key_name                    = "windows"
  subnet_id                   = aws_subnet.flipkart_public_subnet.id
  security_groups             = [aws_security_group.flipkart_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "flipkart_public"
  }
  user_data = file("sample.sh")
}

##security group
resource "aws_security_group" "flipkart_sg" {
  vpc_id = aws_vpc.flipkart.id
  tags = {
    Name = "flipkart_sg"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

##inetrnet gateway
resource "aws_internet_gateway" "flipkart_gateway" {
  vpc_id = aws_vpc.flipkart.id
  tags = {
    Name = "flipkart_internet_gateway"
  }
}

##public route table
resource "aws_route_table" "flipkart_public_rt" {
  vpc_id = aws_vpc.flipkart.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.flipkart_gateway.id
  }
  tags = {
    Name = "flipkart_public_rt"
  }
}

##route assosication public
resource "aws_route_table_association" "flipkart_public_assoc" {
  subnet_id      = aws_subnet.flipkart_public_subnet.id
  route_table_id = aws_route_table.flipkart_public_rt.id
}


##private subnet
resource "aws_subnet" "flipkart_private_subnet" {
  vpc_id                  = aws_vpc.flipkart.id
  cidr_block              = "10.0.0.128/25"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "flipkart_private_subnet"
  }
}



##private instance
resource "aws_instance" "flipkart_private" {
  ami                         = "ami-0f2ce9ce760bd7133"
  instance_type               = "t2.micro"
  key_name                    = "windows"
  subnet_id                   = aws_subnet.flipkart_private_subnet.id
  security_groups             = [aws_security_group.flipkart_sg.id]
  associate_public_ip_address = false
  tags = {
    Name = "flipkart_private"
  }
  user_data = file("sample.sh")
}

##private route table
resource "aws_route_table" "flipkart_private_rt" {
  vpc_id = aws_vpc.flipkart.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.flipkart_nat.id
  }
  tags = {
    Name = "flipkart_private_rt"
  }
}

resource "aws_route_table_association" "flipkart_private_assoc" {
  subnet_id      = aws_subnet.flipkart_private_subnet.id
  route_table_id = aws_route_table.flipkart_private_rt.id
}

resource "aws_eip" "flipkart_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "flipkart_nat" {
  allocation_id = aws_eip.flipkart_nat_eip.id
  subnet_id     = aws_subnet.flipkart_public_subnet.id
  depends_on    = [aws_internet_gateway.flipkart_gateway]
  tags = {
    Name = "flipkart_nat_gateway"
  }
}



output "internet_gateway" {
  value = aws_internet_gateway.flipkart_gateway.id
}

output "vpc_id" {
  value = aws_vpc.flipkart.id
}
output "vpc_cidr_block" {
  value = aws_vpc.flipkart.cidr_block
}

output "subnet_id" {
  value = aws_subnet.flipkart_public_subnet.id
}
output "subnet_cidr_block" {
  value = aws_subnet.flipkart_public_subnet.cidr_block
}