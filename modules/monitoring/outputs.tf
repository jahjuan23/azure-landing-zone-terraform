output "workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.central.id
}

output "workspace_name" {
  description = "Name of the central Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.central.name
}

output "resource_group_name" {
  description = "Management resource group."
  value       = azurerm_resource_group.management.name
}
