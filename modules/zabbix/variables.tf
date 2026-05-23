variable "instance_type" {
  description = "Tipo da instancia EC2 (Zabbix recomenda minimo t3.medium, mas t3.micro funciona para Free Tier)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nome do Key Pair para acesso SSH"
  type        = string
  default     = "deployer"
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile"
  type        = string
  default     = "ECR-TRF"
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "eip_allocation_id" {
  description = "ID do Elastic IP alocado para o Zabbix"
  type        = string
}

variable "user_data_path" {
  description = "Caminho do script de instalação do Zabbix"
  type        = string
}
