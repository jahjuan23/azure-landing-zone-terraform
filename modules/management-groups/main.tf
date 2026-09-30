###############################################################################
# Management group hierarchy (mirrors the Azure Landing Zone reference)
#
#   Tenant Root Group
#   ├── <prefix>-platform
#   │   ├── <prefix>-management
#   │   ├── <prefix>-connectivity
#   │   └── <prefix>-identity
#   ├── <prefix>-landingzones
#   │   ├── <prefix>-corp      <-- the lab subscription is placed here
#   │   └── <prefix>-online
#   └── <prefix>-sandbox
###############################################################################

locals {
  root_id = "/providers/Microsoft.Management/managementGroups/${var.tenant_id}"
}

resource "azurerm_management_group" "platform" {
  name                       = "${var.org_prefix}-platform"
  display_name               = "Platform"
  parent_management_group_id = local.root_id
}

resource "azurerm_management_group" "management" {
  name                       = "${var.org_prefix}-management"
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  name                       = "${var.org_prefix}-connectivity"
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "identity" {
  name                       = "${var.org_prefix}-identity"
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landing_zones" {
  name                       = "${var.org_prefix}-landingzones"
  display_name               = "Landing Zones"
  parent_management_group_id = local.root_id
}

resource "azurerm_management_group" "corp" {
  name                       = "${var.org_prefix}-corp"
  display_name               = "Corp"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "online" {
  name                       = "${var.org_prefix}-online"
  display_name               = "Online"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "sandbox" {
  name                       = "${var.org_prefix}-sandbox"
  display_name               = "Sandbox"
  parent_management_group_id = local.root_id
}

# Place the subscription under Corp so the Landing Zones policies apply to it.
# On `terraform destroy` the subscription moves back to the tenant root.
resource "azurerm_management_group_subscription_association" "lab" {
  management_group_id = azurerm_management_group.corp.id
  subscription_id     = "/subscriptions/${var.subscription_id}"
}
