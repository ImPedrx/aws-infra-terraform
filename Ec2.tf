resource "aws_instance" "ec2-1" {
  ami                    = "ami-0a1b6a02658659c2a"
  instance_type          = "t3.micro"
  key_name               = "deployer"
  vpc_security_group_ids = [aws_security_group.security-group-1.id]
  iam_instance_profile   = "ECR-TRF"
  user_data = file("user_data.sh")

  tags = {
    Name    = "ec2-1"
    manager = "Pedro"
  }
}

resource "aws_security_group" "security-group-1" {
  name        = "security-group-1"
  description = "Firrewall rules for Ec2-1"
  vpc_id      = "vpc-0ebe4b353aa51f708"

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh-access" {
  security_group_id = aws_security_group.security-group-1.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.security-group-1.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow-https" {
  security_group_id = aws_security_group.security-group-1.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}


resource "aws_vpc_security_group_egress_rule" "allow-all-outbound" {

  security_group_id = aws_security_group.security-group-1.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}
