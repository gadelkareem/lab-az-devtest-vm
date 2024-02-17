variable "location" {
  type        = string
  description = "Location of the azure resource group."
  default     = "westeurope"
}

variable "environment" {
  type        = string
  description = "dev, test or production."
  default     = "test"
}

variable "project_name" {
  type        = string
  description = "Project name."
  default     = "myproject"
}

variable "resources_id" {
  type        = string
  description = "Name of the resource ID."
  default     = "myresources"
}

variable "subscription_id" {
  type        = string
  description = "Subscription ID"
  default     = "subscription_id"
}

variable "tenant_id" {
  type        = string
  description = "Tenant ID"
  default     = "tenant_id"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources."
  default     = {}
}

variable "vm_size" {
  type        = string
  description = "virtual machine size"
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  description = "OS admin name for remote access."
  default     = "admin"
}

variable "disk_type" {
  type        = string
  description = "The type of disk to create. Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS, or UltraSSD_LRS."
  default     = "Standard_LRS"
}

variable "ssh_public_key" {
  type        = string
  description = "The type of disk to create. Possible values are Standard_LRS, Premium_LRS, StandardSSD_LRS, or UltraSSD_LRS."
  default     = "public_key"
}

variable "source_ip" {
  type        = string
  description = "Source IP address."
  default     = "127.0.0.1"
}

variable "custom_data" {
  type        = string
  description = "Custom data to be used for cloud-init."
  default     = "127.0.0.1"
}
