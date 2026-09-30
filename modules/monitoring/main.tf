###############################################################################
# Central monitoring + cost guardrail
#
# One Log Analytics workspace that platform and workload resources send
# diagnostics to, plus a subscription budget so the lab can't quietly run up
# a bill.
###############################################################################

resource "azurerm_resource_group" "management" {
  name     = "rg-${var.name_prefix}-management"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "central" {
  name                = "log-${var.name_prefix}-central"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  # Lab guardrail: stop ingesting after 1 GB/day. Remove for real workloads.
  daily_quota_gb = 1

  tags = var.tags
}

resource "azurerm_consumption_budget_subscription" "lab" {
  count = var.enable_budget && var.budget_contact_email != "" ? 1 : 0

  name            = "budget-${var.name_prefix}"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    # Budgets must start on the first of a month. Set once at creation.
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.budget_contact_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_contact_email]
  }

  lifecycle {
    # timestamp() changes every run; don't let it cause a diff after creation.
    ignore_changes = [time_period]
  }
}
