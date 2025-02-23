# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                            = "vm-${var.prefix}-${random_string.main.result}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = var.resource_group_location
  size                           = var.size
  admin_username                  = var.username
  network_interface_ids          = [azurerm_network_interface.main.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
