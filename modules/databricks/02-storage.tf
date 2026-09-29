# ── Main ADLS Gen2 data lake ──────────────────────────────────────────────────
# Separate from the DBFS root (Databricks-managed, hardened in 01-databricks.tf)
# and from Unity Catalog's own dedicated storage (terraform/unity-catalog) —
# this is the workspace's general-purpose data lake. ADLS Gen2, no shared
# key, no public access, private endpoints only.

resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_account_replication_type
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "this" {
  for_each = toset(var.storage_containers)

  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_storage_blob]
  }
}

resource "azurerm_private_endpoint" "storage_dfs" {
  name                = "${var.storage_account_name}-dfs-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-dfs-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dfs-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_storage_dfs]
  }
}
