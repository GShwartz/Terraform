# Configure Resource Group
resource "azurerm_resource_group" "weight_tracker_rg" {
  name     = var.rgname
  location = var.location

  lifecycle {
    prevent_destroy = false
  }

}

# Configure Virtual Network
resource "azurerm_virtual_network" "tf_rg_vnet" {
  name                = var.vnet_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
}

# Configure Subnet for Applications VMS
resource "azurerm_subnet" "application_subnet" {
  name                 = var.subnet_name
  address_prefixes     = [var.frontend_address_prefix]
  resource_group_name  = azurerm_resource_group.weight_tracker_rg.name
  virtual_network_name = azurerm_virtual_network.tf_rg_vnet.name

}

# Configure Subnet for PostgreSQL
resource "azurerm_subnet" "database_subnet" {
  name                 = "Databases"
  address_prefixes     = ["10.200.20.0/24"]
  resource_group_name  = azurerm_resource_group.weight_tracker_rg.name
  virtual_network_name = azurerm_virtual_network.tf_rg_vnet.name

}

# Configure NSG for Applications subnet
resource "azurerm_network_security_group" "applications_nsg" {
  name                = var.webapp_nsg_name
  location            = var.location
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  # Allow SSH Access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2225"
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

  # Deny Everything Else
  security_rule {
    name                       = "Deny_All"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "10.200.10.0/24"
  }

}

# Configure NSG for Databases subnet
resource "azurerm_network_security_group" "databases_nsg" {
  name                = "Databases_NSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  # Allow postgreSQL port
  security_rule {
    name                       = "PostgreSQL"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "10.200.20.0/24"
  }
}

# Connect Application Subnet to NSG
resource "azurerm_subnet_network_security_group_association" "application_subnet_nsg" {
  network_security_group_id = azurerm_network_security_group.applications_nsg.id
  subnet_id                 = azurerm_subnet.application_subnet.id

}

# Connect Databases Subnet to NSG
resource "azurerm_subnet_network_security_group_association" "databases_subnet_nsg" {
  network_security_group_id = azurerm_network_security_group.databases_nsg.id
  subnet_id                 = azurerm_subnet.database_subnet.id

}

# Configure Public IP for Load Balancer
resource "azurerm_public_ip" "tf_vmss_lb_pip" {
  allocation_method   = var.pip_allocation
  location            = var.location
  name                = var.pip_name
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
  sku                 = var.pip_sku

}

# Create a Load Balancer
resource "azurerm_lb" "vmss_lb" {
  location            = var.location
  name                = "Load_Balancer"
  resource_group_name = var.rgname

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.tf_vmss_lb_pip.id
  }

  sku = var.pip_sku

}

# Get Current Load Balancer Public IP Address
data "azurerm_public_ip" "pip" {
  name                = azurerm_public_ip.tf_vmss_lb_pip.name
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}

# Create LB Backend Pool
resource "azurerm_lb_backend_address_pool" "wt_be_pool" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "BackEndAddressPool"

}

# Create an Address Pool for Backend
resource "azurerm_lb_backend_address_pool_address" "backend_addresses" {
  count                   = length(var.nics)
  backend_address_pool_id = azurerm_lb_backend_address_pool.wt_be_pool.id
  virtual_network_id      = azurerm_virtual_network.tf_rg_vnet.id

  ip_address = data.azurerm_network_interface.nics[count.index].private_ip_address
  name       = "backend-${count.index}"

}

# Create Health probe for SSH
resource "azurerm_lb_probe" "lb_probe" {
  name            = "web_access"
  loadbalancer_id = azurerm_lb.vmss_lb.id
  port            = var.web_port

}

# Create Load Balancer Rule for HTTP
resource "azurerm_lb_rule" "lb_http_rule" {
  backend_port                   = var.web_port
  frontend_ip_configuration_name = "PublicIPAddress"
  frontend_port                  = var.web_port
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  name                           = "WebAccess"
  protocol                       = "Tcp"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.wt_be_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id

}

# Create Load Balancer Outbound Rule
resource "azurerm_lb_outbound_rule" "outbound" {
  backend_address_pool_id  = azurerm_lb_backend_address_pool.wt_be_pool.id
  loadbalancer_id          = azurerm_lb.vmss_lb.id
  name                     = "Allow_Any"
  protocol                 = "Tcp"
  allocated_outbound_ports = 64000

}

# Create Public IPs for VM machines
resource "azurerm_public_ip" "pips" {
  count               = length(var.nics)
  allocation_method   = "Static"
  location            = var.location
  name                = "${var.machine_name}${count.index}-PiP"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
  sku                 = "Standard"

}

resource "azurerm_network_interface" "nic_webapp" {
  count               = length(var.nics)
  location            = var.location
  name                = "${var.machine_name}${count.index + 1}-NIC"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  ip_configuration {
    name                          = "config-${count.index}"
    subnet_id                     = azurerm_subnet.application_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = element(var.nics, count.index)
    #    public_ip_address_id          = azurerm_public_ip.pips[count.index].id
    #    public_ip_address_id          = data.azurerm_public_ip.pip.id

  }
}

data "azurerm_network_interface" "nics" {
  count               = 3
  name                = azurerm_network_interface.nic_webapp[count.index].name
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
}

resource "azurerm_network_interface_security_group_association" "app_nsg" {
  count                     = length(var.nics)
  network_interface_id      = azurerm_network_interface.nic_webapp[count.index].id
  network_security_group_id = azurerm_network_security_group.applications_nsg.id
}

resource "azurerm_virtual_machine" "weight_tracker" {
  count                 = 3
  location              = var.location
  name                  = "WeightTrackerVM${count.index + 1}"
  network_interface_ids = [element(azurerm_network_interface.nic_webapp.*.id, count.index)]
  resource_group_name   = var.rgname
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