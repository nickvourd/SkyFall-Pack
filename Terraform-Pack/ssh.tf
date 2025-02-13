# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Output the private key
output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

# Output the public IP
output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

# Output username
output "username" {
  value = var.username
}