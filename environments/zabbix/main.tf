module "zabbix" {
  source = "../../modules/zabbix"

  vpc_id            = var.vpc_id
  eip_allocation_id = var.eip_allocation_id
  user_data_path    = var.user_data_path
}

variable "vpc_id" {}
variable "eip_allocation_id" {}
variable "user_data_path" {}

output "zabbix_public_ip" {
  value = module.zabbix.zabbix_public_ip
}

output "zabbix_ui_url" {
  value = module.zabbix.zabbix_ui_url
}
