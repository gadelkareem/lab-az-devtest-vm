resource "azurerm_public_ip" "ip" {
  count               = 3
  name                = "${local.resource_name}-ip${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${replace(local.resource_name, "/(?i)[^a-z0-9]+/", "")}${random_integer.int.result}vm${count.index + 1}"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_network_interface" "nic" {
  count               = 3
  name                = "${local.resource_name}${random_integer.int.result}-nic${count.index + 1}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.ip.*.id, count.index)
  }

  tags = var.tags

  depends_on = [azurerm_public_ip.ip]
}


resource "azurerm_linux_virtual_machine" "vm" {
  count                           = 3
  name                            = "${local.resource_name}-vm${count.index + 1}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [element(azurerm_network_interface.nic.*.id, count.index)]
  admin_username                  = var.admin_username
  disable_password_authentication = true
  computer_name                   = "${replace(local.resource_name, "/(?i)[^a-z0-9]+/", "")}vm${count.index + 1}"
  custom_data                     = base64encode(var.custom_data)


  # Assign the public key
  admin_ssh_key {
    username   = var.admin_username
    public_key = azurerm_ssh_public_key.ssh_key.public_key
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

  size       = var.vm_size
  tags       = var.tags
  depends_on = [azurerm_network_interface.nic, azurerm_public_ip.ip]
}

resource "azurerm_network_security_rule" "inbound_allow_ssh" {
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "Inbound_Allow_VM_SSH"
  priority                    = 510
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefix       = var.source_ip
  destination_address_prefix  = "*"
  depends_on                  = [azurerm_subnet.subnet, azurerm_network_security_group.nsg]
}


resource "azurerm_network_security_rule" "inbound_allow_vm_http" {
  name                        = "Inbound_Allow_VM_HTTP"
  priority                    = 401
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.source_ip
  destination_address_prefix  = "*"
  description                 = "Inbound_Port_80"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  depends_on                  = [azurerm_network_security_group.nsg]
}
