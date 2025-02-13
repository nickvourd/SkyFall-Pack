# Create a random string for unique names
resource "random_string" "main" {
  length  = 8
  special = false
  upper   = false
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.prefix}-${random_string.main.result}"
  location = var.resource_group_location
}