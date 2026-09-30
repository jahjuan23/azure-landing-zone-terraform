variable "name_prefix" {
  type        = string
  description = "Naming prefix."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "unique_suffix" {
  type        = string
  description = "Suffix that makes the globally unique app name unique."
}

variable "sku_name" {
  type        = string
  description = "App Service plan SKU. B1 or higher is required for VNet integration and private endpoints."

  validation {
    condition     = !contains(["F1", "D1"], var.sku_name)
    error_message = "Free/Shared tiers do not support VNet integration or private endpoints. Use B1 or higher."
  }
}

variable "integration_subnet_id" {
  type        = string
  description = "Subnet delegated to Microsoft.Web/serverFarms for outbound VNet integration."
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet the app's private endpoint is placed in."
}

variable "private_dns_zone_id" {
  type        = string
  description = "privatelink.azurewebsites.net zone ID."
}

variable "workload_identity_id" {
  type        = string
  description = "User-assigned managed identity resource ID."
}

variable "workload_identity_client_id" {
  type        = string
  description = "User-assigned managed identity client ID, exposed to app code as AZURE_CLIENT_ID."
}

variable "log_analytics_id" {
  type        = string
  description = "Central Log Analytics workspace ID."
}

variable "allowed_public_ips" {
  type        = list(string)
  description = "CIDRs allowed to reach the public endpoint. Empty = public access disabled."
}

variable "tags" {
  type        = map(string)
  description = "Tags for every resource."
}
