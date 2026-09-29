# ── Databricks access — two groups, humans only ─────────────────────────────
# reader/contributor each get least-privilege roles across Key Vault and the
# workspace resource. Roles come from var.reader_roles/var.contributor_roles
# (set per environment in terragrunt) — add or remove one there, no module
# change needed. Keys must match access_scopes below. Empty *_group_members
# skips creating that group entirely.

locals {
  access_scopes = {
    key_vault = azurerm_key_vault.this.id
    workspace = azurerm_databricks_workspace.this.id
  }
}

data "azuread_user" "reader" {
  for_each            = toset(var.reader_group_members)
  user_principal_name = each.value
}

data "azuread_user" "contributor" {
  for_each            = toset(var.contributor_group_members)
  user_principal_name = each.value
}

resource "azuread_group" "reader" {
  count            = length(var.reader_group_members) > 0 ? 1 : 0
  display_name     = var.reader_group_name
  security_enabled = true
  members          = [for u in data.azuread_user.reader : u.object_id]
}

resource "azuread_group" "contributor" {
  count            = length(var.contributor_group_members) > 0 ? 1 : 0
  display_name     = var.contributor_group_name
  security_enabled = true
  members          = [for u in data.azuread_user.contributor : u.object_id]
}

resource "azurerm_role_assignment" "reader" {
  for_each = length(var.reader_group_members) > 0 ? var.reader_roles : {}

  scope                = local.access_scopes[each.key]
  role_definition_name = each.value
  principal_id         = azuread_group.reader[0].object_id
  principal_type       = "Group"
}

resource "azurerm_role_assignment" "contributor" {
  for_each = length(var.contributor_group_members) > 0 ? var.contributor_roles : {}

  scope                = local.access_scopes[each.key]
  role_definition_name = each.value
  principal_id         = azuread_group.contributor[0].object_id
  principal_type       = "Group"
}

# ── Key Vault RBAC — Databricks control plane (mandatory, not user-facing) ──
# Every Key-Vault-backed secret scope needs Databricks' own first-party service
# principal ("AzureDatabricks", a fixed appId across all tenants) to read secret
# values on the calling user's behalf. On an access-policy vault this is normally
# granted implicitly when the scope is created via the UI; on an RBAC-mode vault
# (this one) it isn't, and every dbutils.secrets.get()/list-secrets call fails
# with "Caller is not authorized ... ForbiddenByRbac" until this exists — this is
# unrelated to the reader/contributor group membership above.
data "azuread_service_principal" "azure_databricks" {
  client_id = "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
}

resource "azurerm_role_assignment" "azure_databricks_control_plane" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.azure_databricks.object_id
  principal_type       = "ServicePrincipal"
}
