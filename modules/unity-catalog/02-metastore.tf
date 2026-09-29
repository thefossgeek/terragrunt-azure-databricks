locals {
  uc_abfss_url = "abfss://${azurerm_storage_container.unity_catalog.name}@${azurerm_storage_account.unity_catalog.primary_dfs_host}/"
}

# ── Metastore (create-if-not-exists) ────────────────────────────────────────────
# Databricks accounts allow only ONE metastore per region. Rather than a
# per-environment flag, we detect at plan time whether a metastore already
# exists for var.location (e.g. a manually-created dev metastore in the client
# tenant) and only create a new one when none is found (e.g. a from-scratch
# test tenant). Every environment sharing a region shares this same metastore
# and separates itself via an isolated catalog instead (see below).

data "databricks_metastores" "all" {
  provider = databricks.account
}

data "databricks_metastore" "each" {
  for_each     = data.databricks_metastores.all.ids
  provider     = databricks.account
  metastore_id = each.value
}

locals {
  existing_metastore_id = try(
    [for m in data.databricks_metastore.each : m.id if m.region == var.location][0],
    null
  )
  create_new_metastore = local.existing_metastore_id == null
}

resource "databricks_metastore" "this" {
  count = local.create_new_metastore ? 1 : 0

  provider      = databricks.account
  name          = var.metastore_name
  region        = var.location
  storage_root  = local.uc_abfss_url
  force_destroy = var.force_destroy
  # Owner only applies when we're creating a new metastore — never touch the
  # owner of one we're reusing.
  owner = var.owner_group_name
}

locals {
  metastore_id = local.create_new_metastore ? databricks_metastore.this[0].id : local.existing_metastore_id
}

# Metastore-wide default storage credential — only set this up when we're the
# one creating the metastore. If we're reusing an existing metastore (e.g.
# dev's, created manually), it already has a default credential; overwriting
# is_default here would repoint the WHOLE metastore's default credential,
# affecting every other workspace/environment attached to it.
resource "databricks_metastore_data_access" "this" {
  count = local.create_new_metastore ? 1 : 0

  provider     = databricks.account
  metastore_id = local.metastore_id
  name         = azurerm_databricks_access_connector.unity_catalog.name
  is_default   = true

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity_catalog.id
  }
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.account
  metastore_id = local.metastore_id
  workspace_id = var.workspace_numeric_id

  depends_on = [databricks_metastore_data_access.this]
}

# ── Storage credential ─────────────────────────────────────────────────────────
# Per-environment, non-default credential — safe to always create even when
# sharing an existing metastore, since it's additive (named per resource_suffix)
# rather than replacing the metastore's default.

resource "databricks_storage_credential" "unity_catalog" {
  provider      = databricks.workspace
  name          = "cred-${var.resource_suffix}"
  metastore_id  = local.metastore_id
  force_destroy = var.force_destroy

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity_catalog.id
  }

  depends_on = [databricks_metastore_assignment.this]
}

# Azure RBAC role assignments report "created" in the API well before they're
# actually enforced everywhere — without a buffer, the very next call that
# depends on the permission (validating the external location's credential)
# can 403. This is a well-known Azure RBAC propagation delay, not a
# Terraform-level ordering problem, so a plain depends_on isn't enough.
resource "time_sleep" "rbac_propagation" {
  create_duration = "90s"

  depends_on = [
    azurerm_role_assignment.blob_data_contrib,
    azurerm_role_assignment.queue_contrib,
    azurerm_role_assignment.event_contrib,
    azurerm_role_assignment.data_blob_data_contrib,
    azurerm_role_assignment.data_queue_contrib,
    azurerm_role_assignment.data_event_contrib,
  ]
}

# ── External locations ─────────────────────────────────────────────────────────

# Dedicated UC storage external location — used as metastore and catalog root.
resource "databricks_external_location" "unity_catalog" {
  provider        = databricks.workspace
  credential_name = databricks_storage_credential.unity_catalog.name
  name            = azurerm_storage_account.unity_catalog.name
  force_destroy   = var.force_destroy
  url             = local.uc_abfss_url

  depends_on = [
    databricks_metastore_assignment.this,
    time_sleep.rbac_propagation,
  ]
}

# Data ADLS external locations (raw, curated) using the same storage credential.
resource "databricks_external_location" "data" {
  for_each = toset(var.data_storage_containers)

  provider        = databricks.workspace
  credential_name = databricks_storage_credential.unity_catalog.name
  name            = each.value
  force_destroy   = var.force_destroy
  url             = "abfss://${each.value}@${var.data_storage_account_name}.dfs.core.windows.net/"

  depends_on = [
    databricks_metastore_assignment.this,
    time_sleep.rbac_propagation,
  ]
}

# ── Catalog ────────────────────────────────────────────────────────────────────
# storage_root is derived from the external location URL — managed tables created
# here land in customer storage, not Databricks-managed storage.
# ISOLATED mode restricts catalog access to this workspace only.

resource "databricks_catalog" "catalog" {
  provider       = databricks.workspace
  name           = var.catalog_name
  storage_root   = databricks_external_location.unity_catalog.url
  force_destroy  = var.force_destroy
  isolation_mode = var.catalog_isolation_mode
  owner          = var.owner_group_name

  depends_on = [databricks_metastore_assignment.this]
}

# ISOLATED mode (above) locks the catalog down to explicitly bound workspaces
# only — with no binding, NO workspace can read it, including this one.
# provider_config is required here (not just workspace_id) — same reasoning
# as databricks_workspace_conf below: this resource doesn't reliably infer
# the workspace from provider host alone.
resource "databricks_workspace_binding" "this" {
  count = var.catalog_isolation_mode == "ISOLATED" ? 1 : 0

  provider       = databricks.workspace
  securable_name = databricks_catalog.catalog.name
  securable_type = "catalog"
  workspace_id   = var.workspace_numeric_id

  provider_config {
    workspace_id = var.workspace_numeric_id
  }
}

# ── Default namespace ──────────────────────────────────────────────────────────

resource "databricks_default_namespace_setting" "this" {
  count = var.is_default_namespace ? 1 : 0

  provider   = databricks.workspace
  depends_on = [databricks_workspace_binding.this]

  namespace {
    value = databricks_catalog.catalog.name
  }
}
