resource "azurerm_public_ip" "lbip" {
  name                = lower("${local.resource_name}-lbip")
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${replace(local.resource_name, "/(?i)[^a-z0-9]+/", "")}${random_integer.int.result}lbip"
  sku                 = "Standard"
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_lb" "lb" {
  name                = "${local.resource_name}-lb"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "${local.resource_name}-lb-feip"
    public_ip_address_id = azurerm_public_ip.lbip.id
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "${local.resource_name}-bepool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "lbp" {
  name             = "${local.resource_name}-lbprobe"
  loadbalancer_id  = azurerm_lb.lb.id
  port             = 80
  request_path     = "/"
  protocol         = "Http"
  number_of_probes = 1
}

resource "azurerm_lb_rule" "lbrule" {
  name                           = "${local.resource_name}-lbrule"
  loadbalancer_id                = azurerm_lb.lb.id
  probe_id                       = azurerm_lb_probe.lbp.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
}

resource "azurerm_linux_virtual_machine_scale_set" "linux_vmss" {
  name                            = "${local.resource_name}-vmss"
  computer_name_prefix            = "${replace(local.resource_name, "/(?i)[^a-z0-9]+/", "")}vmss"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = var.location
  sku                             = var.vm_size
  instances                       = 3
  admin_username                  = var.admin_username
  disable_password_authentication = true
  health_probe_id                 = azurerm_lb_probe.lbp.id
  provision_vm_agent              = true
  zones                           = [1]
  tags                            = var.tags
  custom_data                     = base64encode(var.custom_data)

  admin_ssh_key {
    username   = var.admin_username
    public_key = azurerm_ssh_public_key.ssh_key.public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                      = "${local.resource_name}-vmssnic"
    primary                   = true
    enable_ip_forwarding      = true
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
      name                                   = "${local.resource_name}-vmssnic-ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.bepool.id]
    }
  }

  automatic_instance_repair {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      tags,
      automatic_instance_repair,
      automatic_os_upgrade_policy,
      rolling_upgrade_policy,
      instances,
      data_disk,
    ]
  }

  depends_on = [azurerm_lb_probe.lbp]
}

resource "azurerm_monitor_autoscale_setting" "auto" {
  name                = "${local.resource_name}-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.linux_vmss.id

  profile {
    name = "default"
    capacity {
      default = 3
      minimum = 3
      maximum = 6
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.linux_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 80
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.linux_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 80
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT1M"
      }
    }
  }
}
