variable "name_prefix" {
  type        = string
  description = "Naming prefix."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "tags" {
  type        = map(string)
  description = "Tags for every resource."
}
