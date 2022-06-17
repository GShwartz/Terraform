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

# Load Balancer Address Pool
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
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]

  depends_on = [azurerm_lb.load_balancer]

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

  depends_on = [azurerm_lb.load_balancer]

}