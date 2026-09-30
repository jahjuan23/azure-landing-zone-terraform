output "management_groups" {
  description = "Management group names (use with az account management-group show --name)."
  value       = module.management_groups.names
}

output "log_analytics_workspace_name" {
  description = "Central Log Analytics workspace."
  value       = module.monitoring.workspace_name
}

output "hub_vnet_name" {
  description = "Hub VNet name."
  value       = module.networking.hub_vnet_name
}

output "spoke_vnet_name" {
  description = "Corp spoke VNet name."
  value       = module.networking.spoke_vnet_name
}

output "app_url" {
  description = "Public URL of the corp app (only reachable from allowed_public_ips)."
  value       = "https://${module.workload.default_hostname}"
}

output "app_private_ip" {
  description = "Private IP of the app's private endpoint inside the spoke."
  value       = module.workload.private_endpoint_ip
}

output "resource_groups" {
  description = "Every resource group this deployment owns."
  value = [
    module.monitoring.resource_group_name,
    module.networking.hub_resource_group_name,
    module.networking.spoke_resource_group_name,
    module.identity.resource_group_name,
    module.workload.resource_group_name,
  ]
}
