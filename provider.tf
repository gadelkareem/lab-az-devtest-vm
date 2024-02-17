provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

resource "random_id" "id" {
  keepers = {
    name = local.resource_name
  }
  byte_length = 6
}

resource "random_integer" "int" {
  min = 100
  max = 999
}
