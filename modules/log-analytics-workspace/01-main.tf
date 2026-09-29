resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  internet_ingestion_enabled   = var.internet_ingestion_enabled
  internet_query_enabled       = var.internet_query_enabled
  local_authentication_enabled = var.local_authentication_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
