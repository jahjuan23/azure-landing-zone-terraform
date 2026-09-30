# Offline tests: `terraform test` plans the whole landing zone against a mock
# provider. No Azure credentials, no cost. Runs in CI.

mock_provider "azurerm" {
  # Mock values are random strings by default; give ID attributes a valid
  # Azure resource ID shape so the provider's ID validation passes.
  mock_resource "azurerm_management_group" {
    defaults = { id = "/providers/Microsoft.Management/managementGroups/mock" }
  }
  mock_resource "azurerm_log_analytics_workspace" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/mock" }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/mock" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/mock" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/mock" }
  }
  mock_resource "azurerm_private_dns_zone" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock" }
  }
  mock_resource "azurerm_service_plan" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Web/serverFarms/mock" }
  }
  mock_resource "azurerm_linux_web_app" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Web/sites/mock" }
  }
}

variables {
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  tenant_id            = "11111111-1111-1111-1111-111111111111"
  org_prefix           = "ci"
  location             = "eastus2"
  allowed_public_ips   = ["203.0.113.10/32"]
  budget_contact_email = "ci@example.com"
}

run "plans_cleanly" {
  command = plan

  assert {
    condition     = output.management_groups.corp == "ci-corp"
    error_message = "Corp management group should be named <prefix>-corp."
  }

  assert {
    condition     = length(output.resource_groups) == 5
    error_message = "Expected five resource groups."
  }

  assert {
    condition     = alltrue([for rg in output.resource_groups : startswith(rg, "rg-ci-prod-")])
    error_message = "Resource groups must follow the rg-<prefix>-prod-* convention."
  }
}

run "rejects_tags_that_violate_policy" {
  command = plan

  variables {
    tags = { owner = "ci" } # missing costCenter and environment
  }

  expect_failures = [check.tags_satisfy_policy]
}

run "rejects_bad_prefix" {
  command = plan

  variables {
    org_prefix = "Not-Valid"
  }

  expect_failures = [var.org_prefix]
}
