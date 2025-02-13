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