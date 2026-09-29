data "databricks_group" "workspace_access" {
  for_each = var.workspace_permission_assignments

  provider     = databricks.account
  display_name = each.key
}

resource "databricks_mws_permission_assignment" "this" {
  for_each = var.workspace_permission_assignments

  provider     = databricks.account
  workspace_id = var.workspace_numeric_id
  principal_id = data.databricks_group.workspace_access[each.key].id
  permissions  = [each.value]
}

resource "databricks_grants" "catalog" {
  provider = databricks.workspace
  catalog  = var.catalog_name

  dynamic "grant" {
    for_each = var.catalog_grants
    content {
      principal  = grant.key
      privileges = grant.value
    }
  }
}
