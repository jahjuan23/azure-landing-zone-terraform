variable "name_prefix" {
  type        = string
  description = "Naming prefix."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "subscription_id" {
  type        = string
  description = "Subscription the budget is scoped to."
}

variable "log_retention_days" {
  type        = number
  description = "Workspace retention in days."
}

variable "enable_budget" {
  type        = bool
  description = "Create the subscription budget."
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget amount."
}

variable "budget_contact_email" {
  type        = string
  description = "Email for budget alerts. Budget is skipped when empty."
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resource group and workspace."
}
