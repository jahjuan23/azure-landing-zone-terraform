variable "tenant_id" {
  type        = string
  description = "Tenant ID; the tenant root management group shares it."
}

variable "org_prefix" {
  type        = string
  description = "Prefix for management group names."
}

variable "subscription_id" {
  type        = string
  description = "Subscription to place under the Corp management group."
}
