resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_name}-rg1"
  location = var.location

  tags = var.tags
}
