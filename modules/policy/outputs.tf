output "assignment_names" {
  description = "Names of every policy assignment this module creates."
  value = concat(
    [
      azurerm_management_group_policy_assignment.allowed_locations.name,
      azurerm_management_group_policy_assignment.allowed_rg_locations.name,
      azurerm_management_group_policy_assignment.audit_storage_https.name,
    ],
    [for a in azurerm_management_group_policy_assignment.require_rg_tag : a.name],
  )
}
