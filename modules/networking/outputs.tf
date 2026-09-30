output "hub_vnet_name" {
  description = "Hub VNet name."
  value       = azurerm_virtual_network.hub.name
}

output "spoke_vnet_name" {
  description = "Corp spoke VNet name."
  value       = azurerm_virtual_network.spoke.name
}

output "hub_resource_group_name" {
  description = "Hub resource group."
  value       = azurerm_resource_group.hub.name
}

output "spoke_resource_group_name" {
  description = "Spoke resource group."
  value       = azurerm_resource_group.spoke.name
}

output "private_endpoint_subnet_id" {
  description = "Subnet for private endpoints in the spoke."
  value       = azurerm_subnet.private_endpoints.id
}

output "app_integration_subnet_id" {
  description = "Subnet delegated to App Service VNet integration."
  value       = azurerm_subnet.app_integration.id
}

output "app_service_private_dns_zone_id" {
  description = "privatelink.azurewebsites.net zone ID."
  value       = azurerm_private_dns_zone.app_service.id
}
