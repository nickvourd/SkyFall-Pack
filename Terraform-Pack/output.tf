output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "username" {
  value = var.username
}

output "connection_string" {
  value = "ssh -i ssh_key.pem ${var.username}@${azurerm_public_ip.main.ip_address}"
}