resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["172.16.1.0/24"]

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = lower("${local.resource_name}-bastionip")
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${replace(local.resource_name, "/(?i)[^a-z0-9]+/", "")}${random_integer.int.result}bastion"
  tags                = var.tags
  sku                 = "Standard"

}

# Upload the public key to Azure
resource "azurerm_ssh_public_key" "ssh_key" {
  name                = "${local.resource_name}-sshkey"
  resource_group_name = azurerm_resource_group.rg.name
  public_key          = var.ssh_public_key
  location            = var.location
}

resource "azurerm_bastion_host" "this" {
  name                   = "${lower(local.resource_name)}-bastion"
  location               = var.location
  resource_group_name    = azurerm_resource_group.rg.name
  sku                    = "Standard"
  ip_connect_enabled     = true
  scale_units            = 2
  copy_paste_enabled     = true
  file_copy_enabled      = true
  shareable_link_enabled = true
  tunneling_enabled      = true

  tags = var.tags

  ip_configuration {
    name                 = "${lower(local.resource_name)}-network"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}
