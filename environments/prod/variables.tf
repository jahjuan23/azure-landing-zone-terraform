variable "subscription_id" {
  type        = string
  description = "Subscription the landing zone deploys into (az account show --query id -o tsv)."
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant ID. The tenant root management group has the same ID (az account show --query tenantId -o tsv)."
}

variable "org_prefix" {
  type        = string
  description = "Short lowercase prefix used in every resource and management group name, e.g. your initials."
  default     = "lz"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.org_prefix))
    error_message = "org_prefix must be 2-6 lowercase letters or digits."
  }
}

variable "location" {
  type        = string
  description = "Primary Azure region. Must be one of allowed_locations or policy will block your own deployment."
  default     = "eastus2"
}

variable "allowed_locations" {
  type        = list(string)
  description = "Regions Azure Policy allows in the landing zones."
  default     = ["eastus", "eastus2", "centralus"]
}

variable "required_tags" {
  type        = list(string)
  description = "Tag keys Azure Policy requires on every resource group in the landing zones."
  default     = ["owner", "costCenter", "environment"]
}

variable "hub_address_space" {
  type        = list(string)
  description = "Address space of the hub VNet."
  default     = ["10.0.0.0/22"]
}

variable "spoke_address_space" {
  type        = list(string)
  description = "Address space of the corp spoke VNet. Must not overlap the hub."
  default     = ["10.1.0.0/22"]
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics retention in days (30 is included in the base price)."
  default     = 30
}

variable "app_service_sku" {
  type        = string
  description = "App Service plan SKU. B1 is the cheapest tier that supports VNet integration and private endpoints."
  default     = "B1"
}

variable "allowed_public_ips" {
  type        = list(string)
  description = "Public IPs (CIDR) allowed to reach the app over the internet, e.g. [\"203.0.113.10/32\"]. Leave empty to make the app private-only."
  default     = []
}

variable "enable_budget" {
  type        = bool
  description = "Create a subscription budget with email alerts."
  default     = true
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget in your billing currency."
  default     = 20
}

variable "budget_contact_email" {
  type        = string
  description = "Email address that receives budget alerts."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource group. Must include every key in required_tags."
  default = {
    owner       = "lab"
    costCenter  = "lab"
    environment = "prod"
    managedBy   = "terraform"
  }
}
