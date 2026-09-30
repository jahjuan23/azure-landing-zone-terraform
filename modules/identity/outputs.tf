output "workload_identity_id" {
  description = "Resource ID of the workload managed identity."
  value       = azurerm_user_assigned_identity.workload.id
}

output "workload_identity_client_id" {
  description = "Client ID of the workload managed identity (what app code uses)."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "resource_group_name" {
  description = "Identity resource group."
  value       = azurerm_resource_group.identity.name
}
