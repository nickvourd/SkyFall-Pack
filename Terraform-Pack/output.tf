output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.main.name
}

output "connection_string" {
  value = "ssh ${var.username}@${azurerm_public_ip.main.ip_address}"
}