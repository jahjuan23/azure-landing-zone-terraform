###############################################################################
# Identity
#
# Deploys what Terraform's azurerm provider can own: a user-assigned managed
# identity that workloads use instead of stored secrets.
#
# Conditional Access and PIM are Entra ID (not ARM) features that need
# Entra ID P1/P2 licences and the azuread provider. Their design is captured
# in docs/adr/03-identity.md, with a ready-to-use template below.
###############################################################################

resource "azurerm_resource_group" "identity" {
  name     = "rg-${var.name_prefix}-identity"
  location = var.location
  tags     = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-${var.name_prefix}-workload"
  resource_group_name = azurerm_resource_group.identity.name
  location            = azurerm_resource_group.identity.location
  tags                = var.tags
}

###############################################################################
# OPTIONAL (needs Entra ID P1 + the hashicorp/azuread provider):
#
# resource "azuread_conditional_access_policy" "mfa_for_admins" {
#   display_name = "CA001: Require MFA for admin roles"
#   state        = "enabledForReportingButNotEnforced" # report-only first
#
#   conditions {
#     client_app_types = ["all"]
#     applications {
#       included_applications = ["All"]
#     }
#     users {
#       included_roles = ["62e90394-69f5-4237-9190-012177145e10"] # Global Administrator
#       excluded_users = ["<break-glass-account-object-id>"]
#     }
#   }
#
#   grant_controls {
#     operator          = "OR"
#     built_in_controls = ["mfa"]
#   }
# }
###############################################################################
