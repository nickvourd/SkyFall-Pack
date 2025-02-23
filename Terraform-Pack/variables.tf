variable "resource_group_location" {
  type        = string
  default     = "westus2"
  description = "Location of the resource group."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "nickvourd"
}

# Add prefix variable for naming consistency
variable "prefix" {
  type        = string
  default     = "vm"
  description = "Prefix for all resources"
}

# Add SSH private key filename variable
variable "ssh_privkey" {
  type        = string
  default     = "ssh_privkey"
  description = "SSH private key filename"
}

# Add DNS name variable
variable "dns_name" {
  type        = string
  description = "DNS name label for the VM's public IP"
  default     = "skyfall"
}

# Add size type variable
variable "size" {
  type        = string
  description = "Azure VM size"
  default     = "Standard_B1ms" 
}