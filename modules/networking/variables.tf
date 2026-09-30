variable "name_prefix" {
  type        = string
  description = "Naming prefix."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "hub_address_space" {
  type        = list(string)
  description = "Hub VNet address space. The first CIDR is split into four /24s (for a /22)."
}

variable "spoke_address_space" {
  type        = list(string)
  description = "Corp spoke VNet address space. The first CIDR is split into four /24s (for a /22)."
}

variable "log_analytics_id" {
  type        = string
  description = "Central Log Analytics workspace for diagnostics."
}

variable "tags" {
  type        = map(string)
  description = "Tags for every resource."
}
