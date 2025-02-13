output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "username" {
  value = var.username
}

output "connection_string" {
  value = "ssh -i ${var.ssh_privkey}.pem ${var.username}@${azurerm_public_ip.main.ip_address}"
}