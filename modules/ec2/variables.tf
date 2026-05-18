variable "instance_type" {
  description = "Tipo da instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "AMI da instancia"
  type        = string
}

variable "key_name" {
  description = "Nome do Key Pair"
  type        = string
  default     = "deployer"
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile para ECR"
  type        = string
  default     = "ECR-TRF"
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, producao)"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "eip_allocation_id" {
  description = "ID do Elastic IP"
  type        = string
}

variable "user_data_path" {
  description = "Caminho do script user data"
  type        = string
}