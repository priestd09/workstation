provider aws {
  region = "us-east-2"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.192.192.0/28"

  tags = {
    Name = "workstation"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = "${aws_vpc.vpc.id}"
  availability_zone = "us-east-2a"
  cidr_block        = "10.192.192.0/28"

  tags = {
    Name = "workstation"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = "${aws_subnet.subnet.id}"
  route_table_id = "${aws_route_table.rt.id}"
}

resource "aws_security_group" "server_default" {
  name        = "server_default"
  description = "Server defaults"
  vpc_id      = "${aws_vpc.vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # mosh (https://mosh.org) ports
  ingress {
    from_port   = 60000
    to_port     = 60010
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "workstation"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "web" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "c5.xlarge"
  subnet_id                   = "${aws_subnet.subnet.id}"
  key_name                    = "provisioning_key"
  associate_public_ip_address = true
  security_groups             = ["${aws_security_group.server_default.id}"]

  tags = {
    Name = "workstation"
  }
}

output "ip" {
  value = "${aws_instance.web.public_ip}"
}
