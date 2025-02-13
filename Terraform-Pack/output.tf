output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "fqdn" {
  value = azurerm_public_ip.main.fqdn
}

output "username" {
  value = var.username
}

output "connection_string" {
  value = "ssh -i ${var.ssh_privkey}.pem ${var.username}@${azurerm_public_ip.main.fqdn}"
}

output "ssh_privkey" {
  value     = var.ssh_privkey
  sensitive = true
}
