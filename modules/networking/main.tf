###############################################################################
# Hub-spoke network
#
#   Hub 10.0.0.0/22                          Corp spoke 10.1.0.0/22
#   ├── AzureFirewallSubnet 10.0.0.0/24      ├── snet-private-endpoints 10.1.0.0/24
#   ├── GatewaySubnet       10.0.1.0/24      └── snet-app-integration   10.1.1.0/24
#   └── snet-shared         10.0.2.0/24          (delegated to App Service)
#
#   Hub <==== peering ====> Spoke
#   Private DNS zone privatelink.azurewebsites.net lives in the hub and is
#   linked to both VNets, so anything in either VNet resolves the app's
#   private endpoint.
###############################################################################

locals {
  hub_cidr   = var.hub_address_space[0]
  spoke_cidr = var.spoke_address_space[0]
}

# ---------------------------------------------------------------- Hub
resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.name_prefix}-hub"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.name_prefix}-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = var.hub_address_space
  tags                = var.tags
}

# Azure requires these exact subnet names for Firewall and VPN/ER gateways.
# They are reserved now so the hub can grow without re-addressing.
resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(local.hub_cidr, 2, 0)]
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(local.hub_cidr, 2, 1)]
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "snet-shared"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [cidrsubnet(local.hub_cidr, 2, 2)]
}

# ---------------------------------------------------------------- Spoke
resource "azurerm_resource_group" "spoke" {
  name     = "rg-${var.name_prefix}-corp-spoke"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.name_prefix}-corp-spoke"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  address_space       = var.spoke_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(local.spoke_cidr, 2, 0)]

  # Make the NSG below actually apply to private endpoints (off by default).
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "app_integration" {
  name                 = "snet-app-integration"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [cidrsubnet(local.spoke_cidr, 2, 1)]

  delegation {
    name = "app-service"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Only HTTPS from inside the network may reach the private endpoints.
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-${var.name_prefix}-private-endpoints"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  tags                = var.tags

  security_rule {
    name                       = "allow-https-from-vnets"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

# ---------------------------------------------------------------- Peering
# Gateway transit stays off until a VPN/ExpressRoute gateway exists in the
# hub; turning it on then lets spokes use the hub's on-prem connection.
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-corp"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-corp-to-hub"
  resource_group_name          = azurerm_resource_group.spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# ---------------------------------------------------------------- Private DNS
resource "azurerm_private_dns_zone" "app_service" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "link-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.app_service.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = "link-corp-spoke"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.app_service.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  tags                  = var.tags
}

# ---------------------------------------------------------------- Diagnostics
resource "azurerm_monitor_diagnostic_setting" "hub_vnet" {
  name                       = "diag-to-central"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "spoke_vnet" {
  name                       = "diag-to-central"
  target_resource_id         = azurerm_virtual_network.spoke.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_metric {
    category = "AllMetrics"
  }
}

###############################################################################
# OPTIONAL: Azure Firewall (secured hub). Roughly $1.25/hour even when idle,
# so it is commented out. To demo it: uncomment, apply, screenshot, destroy.
# Then add a route table on the spoke subnets sending 0.0.0.0/0 to
# azurerm_firewall.hub.ip_configuration[0].private_ip_address.
###############################################################################
#
# resource "azurerm_public_ip" "firewall" {
#   name                = "pip-${var.name_prefix}-fw"
#   resource_group_name = azurerm_resource_group.hub.name
#   location            = azurerm_resource_group.hub.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   tags                = var.tags
# }
#
# resource "azurerm_firewall" "hub" {
#   name                = "afw-${var.name_prefix}-hub"
#   resource_group_name = azurerm_resource_group.hub.name
#   location            = azurerm_resource_group.hub.location
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Basic"
#   tags                = var.tags
#
#   ip_configuration {
#     name                 = "primary"
#     subnet_id            = azurerm_subnet.hub_firewall.id
#     public_ip_address_id = azurerm_public_ip.firewall.id
#   }
# }
