output "zabbix_public_ip" {
  description = "IP publico do servidor Zabbix"
  value       = data.aws_eip.eip.public_ip
}

output "zabbix_instance_id" {
  description = "ID da instancia EC2 do Zabbix"
  value       = aws_instance.zabbix.id
}

output "zabbix_ui_url" {
  description = "URL de acesso a interface web do Zabbix"
  value       = "http://${data.aws_eip.eip.public_ip}"
}
