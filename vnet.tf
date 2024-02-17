resource "azurerm_network_security_group" "nsg" {
  name                = "${local.resource_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.resource_name}-vnet"
  address_space       = ["172.16.0.0/18"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  tags       = var.tags
  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.0.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  depends_on                = [azurerm_network_security_group.nsg, azurerm_virtual_network.vnet]
}
