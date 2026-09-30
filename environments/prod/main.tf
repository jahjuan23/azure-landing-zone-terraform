###############################################################################
# Azure Landing Zone — prod composition
#
# Dependency order:
#   management groups -> policy -> monitoring -> networking -> identity -> workload
#
# Single-subscription lab: the subscription is placed under the Corp
# management group so the landing-zone policies really apply to it.
# See docs/adr/01-governance.md for why, and what a multi-subscription
# enterprise version looks like.
###############################################################################

locals {
  name_prefix = "${var.org_prefix}-prod"

  # Deterministic 6-char suffix for names that must be globally unique
  # (App Service). Derived from the subscription ID, so it is stable across
  # applies without needing the random provider.
  unique_suffix = substr(md5(var.subscription_id), 0, 6)

  missing_tags = setsubtract(var.required_tags, keys(var.tags))
}

# Fail fast at plan time if our own tags would violate our own policy.
check "tags_satisfy_policy" {
  assert {
    condition     = length(local.missing_tags) == 0
    error_message = "var.tags is missing required tag keys: ${join(", ", local.missing_tags)}. Policy will deny the resource groups."
  }
}

# ---------------------------------------------------------------------------
# GOVERNANCE: management group hierarchy + subscription placement
# ---------------------------------------------------------------------------
module "management_groups" {
  source = "../../modules/management-groups"

  tenant_id       = var.tenant_id
  org_prefix      = var.org_prefix
  subscription_id = var.subscription_id
}

# ---------------------------------------------------------------------------
# GOVERNANCE: policy guardrails at the Landing Zones management group
# ---------------------------------------------------------------------------
module "policy" {
  source = "../../modules/policy"

  landing_zones_mg_id = module.management_groups.landing_zones_mg_id
  allowed_locations   = var.allowed_locations
  required_tags       = var.required_tags
}

# ---------------------------------------------------------------------------
# MONITORING: central Log Analytics workspace + cost guardrail
# ---------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix          = local.name_prefix
  location             = var.location
  subscription_id      = var.subscription_id
  log_retention_days   = var.log_retention_days
  enable_budget        = var.enable_budget
  budget_amount        = var.budget_amount
  budget_contact_email = var.budget_contact_email
  tags                 = var.tags

  # Resource groups must be created after the policies exist, so the lab
  # proves our own deployment is compliant rather than racing the policy.
  depends_on = [module.policy]
}

# ---------------------------------------------------------------------------
# NETWORKING: hub-spoke with private DNS
# ---------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  name_prefix         = local.name_prefix
  location            = var.location
  hub_address_space   = var.hub_address_space
  spoke_address_space = var.spoke_address_space
  log_analytics_id    = module.monitoring.workspace_id
  tags                = var.tags

  depends_on = [module.policy]
}

# ---------------------------------------------------------------------------
# IDENTITY: managed identity for workloads (no secrets)
# ---------------------------------------------------------------------------
module "identity" {
  source = "../../modules/identity"

  name_prefix = local.name_prefix
  location    = var.location
  tags        = var.tags

  depends_on = [module.policy]
}

# ---------------------------------------------------------------------------
# WORKLOAD: App Service living in the corp spoke
# ---------------------------------------------------------------------------
module "workload" {
  source = "../../modules/workload"

  name_prefix   = local.name_prefix
  location      = var.location
  unique_suffix = local.unique_suffix
  sku_name      = var.app_service_sku

  integration_subnet_id      = module.networking.app_integration_subnet_id
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.app_service_private_dns_zone_id

  workload_identity_id        = module.identity.workload_identity_id
  workload_identity_client_id = module.identity.workload_identity_client_id
  log_analytics_id            = module.monitoring.workspace_id
  allowed_public_ips          = var.allowed_public_ips
  tags                        = var.tags

  depends_on = [module.policy]
}
