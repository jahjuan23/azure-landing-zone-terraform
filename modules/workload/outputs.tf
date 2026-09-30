output "app_name" {
  description = "App Service name."
  value       = azurerm_linux_web_app.workload.name
}

output "default_hostname" {
  description = "App Service default hostname."
  value       = azurerm_linux_web_app.workload.default_hostname
}

output "private_endpoint_ip" {
  description = "Private IP of the app's private endpoint."
  value       = azurerm_private_endpoint.app.private_service_connection[0].private_ip_address
}

output "resource_group_name" {
  description = "Workload resource group."
  value       = azurerm_resource_group.workload.name
}
