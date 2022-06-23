# Configure Resource Group
resource "azurerm_resource_group" "weight_tracker_rg" {
  name     = var.rg_name
  location = var.location

  lifecycle {
    prevent_destroy = false
  }

}

# Create NSG for Terminal
resource "azurerm_network_security_group" "terminal_nsg" {
  location            = var.location
  name                = "Terminal-NSG"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  # Allow SSH Access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "5.20.19.150"
    destination_address_prefix = "10.0.0.0/24"
  }

}

# Create NSG for App-Servers & DB
resource "azurerm_network_security_group" "apps_nsg" {
  location            = var.location
  name                = "App-Servers-NSG"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  # Allow SSH Access
#  security_rule {
#    name                       = "SSH"
#    priority                   = 1001
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "22"
#    source_address_prefix      = "10.0.0.0/24"
#    destination_address_prefix = "10.0.0.0/24"
#  }

  # Allow HTTP on port 8080
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
  }

}

## Link App-Servers subnet to NSG
#resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
#  network_security_group_id = azurerm_network_security_group.apps_nsg.id
#  subnet_id                 = azurerm_subnet.app_subnet.id
#}

# Link Network Interfaces to NSG
resource "azurerm_network_interface_security_group_association" "nics_nsg" {
  count                     = 3
  network_interface_id      = azurerm_network_interface.nics[count.index].id
  network_security_group_id = azurerm_network_security_group.apps_nsg.id

}

# Link Terminal NIC to NSG
resource "azurerm_network_interface_security_group_association" "terminalsec" {
  network_interface_id      = azurerm_network_interface.terminal-nic.id
  network_security_group_id = azurerm_network_security_group.terminal_nsg.id

}

# Create 3 Network Interfaces
resource "azurerm_network_interface" "nics" {
  count               = 3
  name                = "WebAppVMnic-${count.index + 1}"
  location            = azurerm_resource_group.weight_tracker_rg.location
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  ip_configuration {
    name                          = "WebAppVMnic-${count.index + 1}"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Network Interface for Terminal VM
resource "azurerm_network_interface" "terminal-nic" {
  location            = var.location
  name                = "Terminal-VM"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  ip_configuration {
    name                          = "Terminal"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terminal.id
    subnet_id                     = azurerm_subnet.app_subnet.id

  }

}

# Link Network Interfaces to Load Balancer Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "nics_association" {
  count                   = 3
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_configuration_name   = "WebAppVMnic-${count.index + 1}"
  network_interface_id    = azurerm_network_interface.nics[count.index].id

}



# Create Virtual Machines
resource "azurerm_virtual_machine" "weight_tracker" {
  count                 = 3
  location              = var.location
  name                  = "WeightTrackerVM${count.index + 1}"
  network_interface_ids = [element(azurerm_network_interface.nics.*.id, count.index)]
  resource_group_name   = azurerm_resource_group.weight_tracker_rg.name
  vm_size               = var.vm_type

  storage_os_disk {
    create_option     = var.create_option
    name              = "WeightTrackerVN${count.index + 1}-${var.disk_name}${count.index + 1}"
    caching           = var.disk_catch
    managed_disk_type = var.managed_disk_type
  }

  storage_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.linux_sku
    version   = var.os_version
  }

  os_profile {
    admin_username = var.admin_user
    admin_password = var.admin_password
    computer_name  = "weighttracker${count.index}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Create Terminal VM
resource "azurerm_linux_virtual_machine" "terminal" {
  computer_name                   = "terminal"
  admin_username                  = var.admin_user
  admin_password                  = var.admin_password
  location                        = var.location
  name                            = "Terminal-Main"
  network_interface_ids           = [azurerm_network_interface.terminal-nic.id]
  resource_group_name             = azurerm_resource_group.weight_tracker_rg.name
  size                            = var.vm_type
  disable_password_authentication = false

  os_disk {
    caching              = var.disk_catch
    storage_account_type = var.managed_disk_type
  }

  source_image_reference {
    offer     = var.offer
    publisher = var.publisher
    sku       = var.linux_sku
    version   = var.os_version
  }

}
