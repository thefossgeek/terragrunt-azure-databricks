data "azurerm_client_config" "current" {}

locals {
  # Construct the managed DBFS storage account resource ID so private endpoints
  # and network rules can reference it in the same apply as the workspace,
  # without a data source lookup that would fail on the first run.
  dbfs_storage_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.managed_resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.managed_dbfs_storage_account_name}"
}

resource "azurerm_databricks_workspace" "this" {
  name                                  = var.name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  managed_resource_group_name           = var.managed_resource_group_name
  sku                                   = var.sku
  infrastructure_encryption_enabled     = var.infrastructure_encryption_enabled
  public_network_access_enabled         = var.public_network_access_enabled
  network_security_group_rules_required = var.network_security_group_rules_required
  tags                                  = var.tags

  # Storage firewall on the Databricks-managed DBFS root, via the dedicated
  # access connector below. Adds a network ACL on top of the DBFS private
  # endpoints already provisioned further down (defense-in-depth) — this is
  # the only supported way to firewall that account, since a Deny Assignment
  # on its managed resource group blocks direct azurerm_storage_account_network_rules.
  default_storage_firewall_enabled = var.enable_dbfs_storage_firewall
  access_connector_id              = var.enable_dbfs_storage_firewall ? azurerm_databricks_access_connector.workspace_storage[0].id : null

  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = var.virtual_network_id
    private_subnet_name                                  = var.databricks_private_subnet_name
    public_subnet_name                                   = var.databricks_public_subnet_name
    private_subnet_network_security_group_association_id = var.databricks_private_subnet_nsg_association_id
    public_subnet_network_security_group_association_id  = var.databricks_public_subnet_nsg_association_id
    storage_account_name                                 = var.managed_dbfs_storage_account_name
    storage_account_sku_name                             = var.managed_dbfs_storage_sku_name
  }

  # Enhanced Security and Compliance Add-On.
  # compliance_security_profile_enabled is PERMANENT once set to true —
  # it cannot be disabled without destroying the workspace.
  enhanced_security_compliance {
    automatic_cluster_update_enabled      = var.automatic_cluster_update_enabled
    compliance_security_profile_enabled   = var.compliance_security_profile_enabled
    compliance_security_profile_standards = var.compliance_security_profile_standards
    enhanced_security_monitoring_enabled  = var.enhanced_security_monitoring_enabled
  }
}

resource "azurerm_databricks_access_connector" "this" {
  name                = var.access_connector_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_access_connector" "workspace_storage" {
  count = var.enable_dbfs_storage_firewall ? 1 : 0

  # Distinct from azurerm_databricks_access_connector.this (external ADLS grants) —
  # this connector is dedicated to the workspace's own DBFS root storage firewall.
  name                = coalesce(var.workspace_storage_access_connector_name, "${var.access_connector_name}-dbfs")
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
}

resource "azurerm_private_endpoint" "workspace_ui_api" {
  name                = "${var.name}-ui-api-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-ui-api-psc"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_databricks]
  }
}

resource "azurerm_private_endpoint" "browser_auth" {
  name                = "${var.name}-browser-auth-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-browser-auth-psc"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["browser_authentication"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-browser-auth-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_databricks]
  }

  # Private endpoints against the same Databricks workspace resource must be
  # created serially — Azure's Databricks resource provider throws
  # "ConcurrentUpdateError" if two PE registrations against the same
  # workspace run in parallel.
  depends_on = [azurerm_private_endpoint.workspace_ui_api]
}

resource "azurerm_private_endpoint" "backend" {
  name                = "${var.name}-backend-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-backend-psc"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "databricks-backend-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_databricks]
  }

  depends_on = [azurerm_private_endpoint.browser_auth]
}

# ── DBFS root storage hardening ────────────────────────────────────────────
# The blob + dfs private endpoints are created in the same apply as the
# workspace because we construct the storage account resource ID from the
# known name rather than using a data source (which cannot resolve until
# after the workspace exists).

resource "azurerm_private_endpoint" "dbfs_blob" {
  name                = "${var.name}-dbfs-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-dbfs-blob-psc"
    private_connection_resource_id = local.dbfs_storage_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dbfs-blob-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_storage_blob]
  }

  depends_on = [azurerm_databricks_workspace.this]
}

resource "azurerm_private_endpoint" "dbfs_dfs" {
  name                = "${var.name}-dbfs-dfs-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.name}-dbfs-dfs-psc"
    private_connection_resource_id = local.dbfs_storage_id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dbfs-dfs-dns-zone-group"
    private_dns_zone_ids = [var.dns_zone_id_storage_dfs]
  }

  depends_on = [azurerm_databricks_workspace.this]
}
