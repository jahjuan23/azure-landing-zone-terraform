###############################################################################
# Corp workload: a Linux App Service that consumes the platform
#
#   Inbound  (private) : client in hub/spoke -> private endpoint 10.1.0.x -> app
#   Inbound  (public)  : only from allowed_public_ips, everything else 403
#   Outbound           : app -> VNet integration subnet -> spoke (-> hub)
#   Identity           : user-assigned managed identity, no secrets
#   Logs               : HTTP + console logs -> central Log Analytics
#
# Regional VNet integration is OUTBOUND only. Private inbound needs the
# private endpoint. See docs/adr/05-private-access.md.
###############################################################################

resource "azurerm_resource_group" "workload" {
  name     = "rg-${var.name_prefix}-corp-app"
  location = var.location
  tags     = var.tags
}

resource "azurerm_service_plan" "workload" {
  name                = "asp-${var.name_prefix}-corp"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "workload" {
  name                = "app-${var.name_prefix}-corp-${var.unique_suffix}"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  service_plan_id     = azurerm_service_plan.workload.id
  tags                = var.tags

  https_only = true

  # Public endpoint only exists if you allow-listed an IP; otherwise the app
  # is reachable solely through the private endpoint.
  public_network_access_enabled = length(var.allowed_public_ips) > 0

  # Outbound traffic leaves through the spoke.
  virtual_network_subnet_id = var.integration_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.workload_identity_id]
  }

  site_config {
    always_on              = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    http2_enabled          = true
    vnet_route_all_enabled = true

    application_stack {
      node_version = "22-lts"
    }

    # Deny by default; allow only listed IPs. Does not affect the private
    # endpoint, which is governed by the spoke NSG instead.
    ip_restriction_default_action = "Deny"

    dynamic "ip_restriction" {
      for_each = var.allowed_public_ips
      content {
        name       = "allow-${ip_restriction.key}"
        priority   = 100 + ip_restriction.key
        action     = "Allow"
        ip_address = ip_restriction.value
      }
    }

    # Keep the Kudu/SCM site locked down the same way.
    scm_ip_restriction_default_action = "Deny"
  }

  app_settings = {
    AZURE_CLIENT_ID = var.workload_identity_client_id
  }
}

# Private inbound path. The DNS zone group writes the A record into
# privatelink.azurewebsites.net automatically.
resource "azurerm_private_endpoint" "app" {
  name                = "pe-${azurerm_linux_web_app.workload.name}"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-app"
    private_connection_resource_id = azurerm_linux_web_app.workload.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "diag-to-central"
  target_resource_id         = azurerm_linux_web_app.workload.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  # Requests evaluated by access restrictions (who was allowed or blocked).
  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
