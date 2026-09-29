locals {
  uc_storage_account_name = substr(lower(replace("stuc${var.resource_suffix}", "-", "")), 0, 24)
  access_connector_mi_id  = azurerm_databricks_access_connector.unity_catalog.identity[0].principal_id
}

# ── Dedicated Access Connector for Unity Catalog ───────────────────────────────

resource "azurerm_databricks_access_connector" "unity_catalog" {
  name                = "id-databricks-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ── Dedicated storage account for Unity Catalog ────────────────────────────────
# HNS enabled (ADLS Gen2); network deny with bypass = None is stricter than
# AzureServices — only the AC above can reach this storage via Private Link.

resource "azurerm_storage_account" "unity_catalog" {
  name                            = local.uc_storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_account_replication_type
  is_hns_enabled                  = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  tags                            = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
    private_link_access {
      endpoint_resource_id = azurerm_databricks_access_connector.unity_catalog.id
    }
  }
}

resource "azurerm_storage_container" "unity_catalog" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.unity_catalog.id
  container_access_type = "private"
}

# ── RBAC on the dedicated UC storage account ───────────────────────────────────
# All three roles are required: Blob for data read/write, Queue and EventGrid
# for Delta Sharing event-notification features used by Unity Catalog.

resource "azurerm_role_assignment" "blob_data_contrib" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.access_connector_mi_id
}

resource "azurerm_role_assignment" "queue_contrib" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = local.access_connector_mi_id
}

resource "azurerm_role_assignment" "event_contrib" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = local.access_connector_mi_id
}

# ── RBAC on the data ADLS (raw, curated external locations) ───────────────────

resource "azurerm_role_assignment" "data_blob_data_contrib" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.access_connector_mi_id
}

resource "azurerm_role_assignment" "data_queue_contrib" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = local.access_connector_mi_id
}

resource "azurerm_role_assignment" "data_event_contrib" {
  scope                = var.data_storage_account_id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = local.access_connector_mi_id
}
