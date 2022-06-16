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

resource "azurerm_subnet_network_security_group_association" "apps_nsg_link" {
  network_security_group_id = azurerm_network_security_group.apps_nsg.id
  subnet_id                 = azurerm_subnet.app_subnet.id

}

resource "azurerm_public_ip" "load_balancer_pip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "Load_Balancer_PiP"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
  sku                 = "Standard"

}

# ==================================================================== #
# Load Balancer #
# ==================================================================== #
resource "azurerm_lb" "load_balancer" {
  location            = var.location
  name                = "Load_Balancer"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  frontend_ip_configuration {
    name                          = "PublicIPAddress"
    public_ip_address_id          = azurerm_public_ip.load_balancer_pip.id
  }

  sku = "Standard"

}

# ===================================== #
# Load Balancer Address Pool & Addresses
# ===================================== #
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "BackEndAddressPool"
}

# ==================================================================== #

data "azurerm_public_ip" "load_balancer_pip_data" {
  name                = azurerm_public_ip.load_balancer_pip.name
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
}

resource "azurerm_network_interface" "nic01" {
  count = 3
  name                = "WebAppVMnic-${count.index}"
  location            = azurerm_resource_group.weight_tracker_rg.location
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

  ip_configuration {
    name                          = "WebAppVMnic-${count.index}"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nics_association" {
  count = 3
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_configuration_name   = "WebAppVMnic-${count.index}"
  network_interface_id    = azurerm_network_interface.nic01[count.index].id

}
