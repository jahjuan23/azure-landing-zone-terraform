output "landing_zones_mg_id" {
  description = "Resource ID of the Landing Zones management group."
  value       = azurerm_management_group.landing_zones.id
}

output "platform_mg_id" {
  description = "Resource ID of the Platform management group."
  value       = azurerm_management_group.platform.id
}

output "corp_mg_id" {
  description = "Resource ID of the Corp management group."
  value       = azurerm_management_group.corp.id
}

output "names" {
  description = "Management group names keyed by role."
  value = {
    platform      = azurerm_management_group.platform.name
    management    = azurerm_management_group.management.name
    connectivity  = azurerm_management_group.connectivity.name
    identity      = azurerm_management_group.identity.name
    landing_zones = azurerm_management_group.landing_zones.name
    corp          = azurerm_management_group.corp.name
    online        = azurerm_management_group.online.name
    sandbox       = azurerm_management_group.sandbox.name
  }
}
