resource "aws_vpc" "vpc2" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Terraaws"
  }
}
resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Publicsub"
  }
}
resource "aws_subnet" "sub2" {
  vpc_id     = aws_vpc.vpc2.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Privatesub"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "PublicRT"
  }
}

resource "aws_route_table" "prvrt" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "PrivateRT"
  }
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.pubrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "publicsb" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_route_table_association" "privtsub" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.prvrt.id
}

resource "aws_eip" "elastic" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.elastic.id
  subnet_id     = aws_subnet.sub1.id

  tags = {
    Name = "NATgw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.prvrt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

resource "aws_security_group" "mysg" {
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

resource "aws_instance" "Public" {
  ami           = "ami-05d2d839d4f73aafb"
  instance_type = "c7i-flex.large"
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  key_name = "KP3"
  subnet_id = aws_subnet.sub1.id
  vpc_security_group_ids = [aws_security_group.mysg.id]

  tags = {
    Name = "Public1"
  }
}


