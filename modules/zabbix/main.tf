resource "aws_instance" "zabbix" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.zabbix_sg.id]
  iam_instance_profile   = var.iam_instance_profile
  user_data              = file(var.user_data_path)

  tags = {
    Name        = "ec2-zabbix"
    Environment = "monitoring"
    Manager     = "Terraform"
  }
}

data "aws_eip" "eip" {
  id = var.eip_allocation_id
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.zabbix.id
  allocation_id = data.aws_eip.eip.id
}

resource "aws_security_group" "zabbix_sg" {
  name        = "security-group-zabbix"
  description = "Security Group - Zabbix Monitoring Server"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "security-group-zabbix"
    Environment = "monitoring"
    Manager     = "Terraform"
  }
}

# SSH
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.zabbix_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# HTTP - Interface web do Zabbix
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.zabbix_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# HTTPS
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.zabbix_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Zabbix trapper - recebe dados dos agentes (active checks)
resource "aws_vpc_security_group_ingress_rule" "zabbix_trapper" {
  security_group_id = aws_security_group.zabbix_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 10051
  ip_protocol       = "tcp"
  to_port           = 10051
}

# Todo tráfego de saída
resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.zabbix_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}
