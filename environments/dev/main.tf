module "ec2" {
  source = "../../modules/ec2"

  environment          = var.environment
  ami                  = var.ami
  vpc_id               = var.vpc_id
  eip_allocation_id    = var.eip_allocation_id
  user_data_path       = var.user_data_path
}

variable "environment" {}
variable "ami" {}
variable "vpc_id" {}
variable "eip_allocation_id" {}
variable "user_data_path" {}

output "ec2_public_ip" {
  value = module.ec2.ec2_public_ip
}