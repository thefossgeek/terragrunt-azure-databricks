resource "azurerm_private_endpoint" "dfs" {
  name                = "pe-uc-${var.resource_suffix}-dfs"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-uc-${var.resource_suffix}-dfs"
    private_connection_resource_id = azurerm_storage_account.unity_catalog.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "uc-dfs-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_ids["dfs"]]
  }
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-uc-${var.resource_suffix}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-uc-${var.resource_suffix}-blob"
    private_connection_resource_id = azurerm_storage_account.unity_catalog.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "uc-blob-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_ids["blob"]]
  }
}

# ── NCC + auto-approval for serverless compute ─────────────────────────────────
# Each module call: (1) creates the NCC private endpoint rule so Databricks
# serverless compute can reach the UC storage privately, (2) reads back the
# pending PE connection, and (3) auto-approves it via AzAPI.
# Requires ncc_id to be set (a Network Connectivity Config already attached to
# the workspace). Leave ncc_id null if serverless is not in use.
#
# providers passes databricks.account because the NCC rule is an account-level
# resource; the self-approving-pe module uses the default (unaliased) databricks
# provider, which we map here.

module "ncc_dfs" {
  count  = local.ncc_in_use ? 1 : 0
  source = "./self-approving-pe"

  providers = {
    databricks = databricks.account
  }

  databricks_account_id            = var.databricks_account_id
  network_connectivity_config_id   = local.ncc_id_effective
  network_connectivity_config_name = local.ncc_name_effective
  group_id                         = "dfs"
  resource_id                      = azurerm_storage_account.unity_catalog.id
}

module "ncc_blob" {
  count  = local.ncc_in_use ? 1 : 0
  source = "./self-approving-pe"

  providers = {
    databricks = databricks.account
  }

  databricks_account_id            = var.databricks_account_id
  network_connectivity_config_id   = local.ncc_id_effective
  network_connectivity_config_name = local.ncc_name_effective
  group_id                         = "blob"
  resource_id                      = azurerm_storage_account.unity_catalog.id
}

# ── NCC + auto-approval for the main data-lake storage account ─────────────────
# Same as ncc_dfs/ncc_blob above, but for the raw/curated external-location
# storage account (var.data_storage_account_id) instead of the dedicated UC
# metastore storage account. Without these, serverless compute can reach
# managed UC tables privately but has no private path to raw/curated at all.

module "ncc_data_lake_dfs" {
  count  = local.ncc_in_use ? 1 : 0
  source = "./self-approving-pe"

  providers = {
    databricks = databricks.account
  }

  databricks_account_id            = var.databricks_account_id
  network_connectivity_config_id   = local.ncc_id_effective
  network_connectivity_config_name = local.ncc_name_effective
  group_id                         = "dfs"
  resource_id                      = var.data_storage_account_id
}

module "ncc_data_lake_blob" {
  count  = local.ncc_in_use ? 1 : 0
  source = "./self-approving-pe"

  providers = {
    databricks = databricks.account
  }

  databricks_account_id            = var.databricks_account_id
  network_connectivity_config_id   = local.ncc_id_effective
  network_connectivity_config_name = local.ncc_name_effective
  group_id                         = "blob"
  resource_id                      = var.data_storage_account_id
}

# ── NCC + auto-approval for Key Vault ───────────────────────────────────────────
# Only needed if serverless code calls the Key Vault SDK directly. Regular
# dbutils.secrets.get() against a Key-Vault-backed scope is control-plane
# mediated and already works without this — see terraform/databricks-secret-acl.

module "ncc_key_vault" {
  count  = local.ncc_in_use && var.key_vault_id != null ? 1 : 0
  source = "./self-approving-pe"

  providers = {
    databricks = databricks.account
  }

  databricks_account_id            = var.databricks_account_id
  network_connectivity_config_id   = local.ncc_id_effective
  network_connectivity_config_name = local.ncc_name_effective
  group_id                         = "vault"
  resource_id                      = var.key_vault_id

  # Key Vault's ARM shape differs from storage accounts (module defaults).
  data_api_type   = "Microsoft.KeyVault/vaults@2023-07-01"
  update_api_type = "Microsoft.KeyVault/vaults/privateEndpointConnections@2023-07-01"
}
