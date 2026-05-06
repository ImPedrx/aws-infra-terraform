resource "aws_instance" "ec2-1" {
  ami                    = "ami-0a1b6a02658659c2a"
  instance_type          = "t3.micro"
  key_name               = "deployer"
  vpc_security_group_ids = [aws_security_group.security-group-1.id]
  iam_instance_profile   = "ECR-TRF"
  user_data = file("user_data.sh")

  tags = {
    Name    = "ec2-1"
    manager = "Pedro3"
  }
}

# Busca o Elastic IP já existente (criado manualmente na AWS)
data "aws_eip" "ec2_ip" {
  id = "eipalloc-0120c9075d83de696"
}

# Associa o Elastic IP à instância
resource "aws_eip_association" "ec2_ip_assoc" {
  instance_id   = aws_instance.ec2-1.id
  allocation_id = data.aws_eip.ec2_ip.id
}

# Output do IP
output "ec2_public_ip" {
  value = data.aws_eip.ec2_ip.public_ip
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

resource "aws_vpc_security_group_ingress_rule" "allow-9090" {
  security_group_id = aws_security_group.security-group-1.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 9090
  ip_protocol = "tcp"
  to_port     = 9090
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