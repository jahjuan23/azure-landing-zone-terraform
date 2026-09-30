###############################################################################
# Governance guardrails, assigned at the Landing Zones management group so
# every current and future subscription beneath it inherits them.
#
# All definitions are Azure built-ins, referenced by their stable GUIDs.
# Assignment names at management-group scope are limited to 24 characters.
###############################################################################

locals {
  builtin = "/providers/Microsoft.Authorization/policyDefinitions"
}

# Resources may only be deployed to approved regions (Deny).
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations"
  description          = "Resources may only be created in approved regions."
  management_group_id  = var.landing_zones_mg_id
  policy_definition_id = "${local.builtin}/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })

  non_compliance_message {
    content = "This region is not approved for landing zone workloads."
  }
}

# The policy above does not cover resource groups themselves, so a second
# built-in is needed for them — a common exam trap.
resource "azurerm_management_group_policy_assignment" "allowed_rg_locations" {
  name                 = "allowed-rg-locations"
  display_name         = "Allowed locations for resource groups"
  description          = "Resource groups may only be created in approved regions."
  management_group_id  = var.landing_zones_mg_id
  policy_definition_id = "${local.builtin}/e765b5de-1225-4ba3-bd56-1ac6695af988"

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })

  non_compliance_message {
    content = "Resource groups must be created in an approved region."
  }
}

# Every resource group must carry each required tag (Deny), one assignment
# per tag key.
resource "azurerm_management_group_policy_assignment" "require_rg_tag" {
  for_each = toset(var.required_tags)

  name                 = substr("rg-tag-${lower(each.value)}", 0, 24)
  display_name         = "Require '${each.value}' tag on resource groups"
  management_group_id  = var.landing_zones_mg_id
  policy_definition_id = "${local.builtin}/96670d01-0a4d-4649-9c89-2d3abc0a5025"

  parameters = jsonencode({
    tagName = { value = each.value }
  })

  non_compliance_message {
    content = "Resource groups must have a '${each.value}' tag."
  }
}

# Audit-only example: flag storage accounts that allow plain HTTP. Shows the
# Audit vs Deny distinction without blocking anything.
resource "azurerm_management_group_policy_assignment" "audit_storage_https" {
  name                 = "audit-storage-https"
  display_name         = "Audit: storage accounts must require secure transfer"
  management_group_id  = var.landing_zones_mg_id
  policy_definition_id = "${local.builtin}/404c3081-a854-4457-ae30-26a93ef643f9"
}
