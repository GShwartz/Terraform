data "azurerm_resource_group" "resource_group" {
  name = azurerm_resource_group.weight_tracker_rg.name

}

data "azurerm_virtual_network" "virtual_network" {
  name                = "Weight_Tracker_With_Terraform-vnet"
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}

data "azurerm_public_ip" "terminal_pip" {
  name                = azurerm_public_ip.terminal.name
  resource_group_name = azurerm_resource_group.weight_tracker_rg.name

}
 