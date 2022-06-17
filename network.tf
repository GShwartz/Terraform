# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  name                = "Weight_Tracker_Vnet"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}

resource "azurerm_subnet" "app_subnet" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "App-Servers"
  resource_group_name  = azurerm_resource_group.weight_tracker_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [azurerm_resource_group.weight_tracker_rg]

}

# Create Public IP for Load Balancer
resource "azurerm_public_ip" "load_balancer_pip" {
  allocation_method   = "Static"
  location            = var.location
  name                = "Load_Balancer_PiP"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name
  sku                 = "Standard"

}

# Create connection machine nic
resource "azurerm_public_ip" "terminal" {
  allocation_method   = "Dynamic"
  location            = var.location
  name                = "Terminal-PiP"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}