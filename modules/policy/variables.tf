variable "landing_zones_mg_id" {
  type        = string
  description = "Resource ID of the Landing Zones management group."
}

variable "allowed_locations" {
  type        = list(string)
  description = "Regions permitted by policy."
}

variable "required_tags" {
  type        = list(string)
  description = "Tag keys required on resource groups."
}
