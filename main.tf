# Configure Resource Group
resource "azurerm_resource_group" "weight_tracker_rg" {
  name     = var.rg_name
  location = var.location

  lifecycle {
    prevent_destroy = false
  }

}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.200.0.0/16"]
  location            = var.location
  name                = "Weight_Tracker_Vnet"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}

resource "azurerm_subnet" "app_subnet" {
  address_prefixes     = ["10.200.10.0/24"]
  name                 = "App-Servers"
  resource_group_name  = azurerm_resource_group.weight_tracker_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [azurerm_resource_group.weight_tracker_rg]
}

resource "azurerm_network_security_group" "apps_nsg" {
  location            = var.location
  name                = "App-Servers-NSG"
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
    source_address_prefix      = "*"
    destination_address_prefix = "10.200.10.0/24"
  }

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
    destination_address_prefix = "10.200.10.0/24"
  }
}

## Link Subnet to NSG
#resource "azurerm_subnet_network_security_group_association" "apps_nsg_link" {
#  network_security_group_id = azurerm_network_security_group.apps_nsg.id
#  subnet_id                 = azurerm_subnet.app_subnet.id
#
#}

# Create Public IP
resource "azurerm_public_ip" "load_balancer_pip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "Load_Balancer_PiP"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
  sku                 = "Standard"

}

# Create Load Balancer
resource "azurerm_lb" "load_balancer" {
  location            = var.location
  name                = "Load_Balancer"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.load_balancer_pip.id
  }

  sku = "Standard"

}

# Load Balancer Address Pool & Addresses
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "BackEndAddressPool"

  depends_on = [azurerm_lb.load_balancer]

}

resource "azurerm_lb_probe" "web_probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "HTTP_Probe"
  port            = 8080

  depends_on = [azurerm_lb.load_balancer]

}

resource "azurerm_lb_probe" "ssh_probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "SSH_Probe"
  port            = 22

  depends_on = [azurerm_lb.load_balancer]

}

resource "azurerm_lb_rule" "web" {
  backend_port                   = 8080
  frontend_ip_configuration_name = "PublicIPAddress"
  frontend_port                  = 8080
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "Web"
  protocol                       = "Tcp"
  probe_id                       = azurerm_lb_probe.web_probe.id
  disable_outbound_snat          = true
  depends_on                     = [azurerm_lb.load_balancer]

}

# Create Load Balancer NAT Rule
resource "azurerm_lb_nat_rule" "nat_rule_ssh" {
  name                           = "SSH"
  resource_group_name            = azurerm_resource_group.weight_tracker_rg.name
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  frontend_port                  = 22
  loadbalancer_id                = azurerm_lb.load_balancer.id
  protocol                       = "Tcp"

  depends_on = [azurerm_lb.load_balancer]
}

resource "azurerm_lb_outbound_rule" "outbound" {
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  loadbalancer_id         = azurerm_lb.load_balancer.id
  name                    = "Any"
  protocol                = "All"

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }

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

# Link Network Interfaces to Load Balancer Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "nics_association" {
  count                   = 3
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_configuration_name   = "WebAppVMnic-${count.index + 1}"
  network_interface_id    = azurerm_network_interface.nics[count.index].id

}

resource "azurerm_network_interface_security_group_association" "nics_nsg" {
  count                     = 3
  network_interface_id      = azurerm_network_interface.nics[count.index].id
  network_security_group_id = azurerm_network_security_group.apps_nsg.id

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

# Create connection machine nic
resource "azurerm_public_ip" "terminal" {
  allocation_method   = "Dynamic"
  location            = var.location
  name                = "Terminal-PiP"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}

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

resource "azurerm_network_interface_security_group_association" "terminalsec" {
  network_interface_id      = azurerm_network_interface.terminal-nic.id
  network_security_group_id = azurerm_network_security_group.apps_nsg.id

}

resource "azurerm_linux_virtual_machine" "terminal" {
  computer_name                   = "terminal"
  admin_username                  = var.admin_user
  admin_password                  = var.admin_password
  location                        = var.location
  name                            = "terminal"
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
