# ---------------------------------------------------------------------------
# Diagnostic Settings — Databricks + storage → Log Analytics
# category_group "allLogs" captures every log category Databricks emits
# (clusters, jobs, notebook, secrets, unityCatalog, sqlPermissions, RBAC,
# webTerminal, gitCredentials, etc. — 60+ categories) and any future ones
# automatically, without requiring module changes.
# ---------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "databricks" {
  name                       = "databricks-diagnostics"
  target_resource_id         = azurerm_databricks_workspace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  # No enabled_metric block: Azure Databricks workspaces don't publish
  # platform metrics (unlike most Azure resources) — "AllMetrics" fails with
  # "Metric export is not enabled." Only log categories apply here.
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "keyvault-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "storage-diagnostics"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  # Blob service diagnostics don't expose an "AllMetrics" category (unlike
  # most Azure resource types) — only these two real categories exist. Using
  # "AllMetrics" here causes a perpetual plan diff since Azure normalizes it
  # back to Capacity + Transaction on every refresh.
  enabled_metric {
    category = "Transaction"
  }

  enabled_metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_action_group" "this" {
  name                = "${var.name}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "platform"

  email_receiver {
    name          = "platform-team"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "storage_availability" {
  name                = "${var.name}-storage-availability"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_storage_account.this.id]
  severity            = 1
  frequency           = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99.9
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}
