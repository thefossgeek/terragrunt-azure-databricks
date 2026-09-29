prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/unity-catalog-access"
}

inputs = {
  subscription_id          = values.subscription_id
  tenant_id                = values.tenant_id
  location                 = values.location
  location_code            = values.location_code
  environment              = values.environment
  databricks_account_id    = values.databricks_account_id
  databricks_workspace_url = dependency.databricks.outputs.workspace_url
  tags                     = values.tags

  workspace_numeric_id = dependency.databricks.outputs.workspace_numeric_id
  catalog_name          = dependency.unity_catalog.outputs.catalog_name

  workspace_permission_assignments = {
    (dependency.unity_catalog_groups.outputs.group_display_names["workspace_admins"]) = "ADMIN"
    (dependency.unity_catalog_groups.outputs.group_display_names["workspace_users"])  = "USER"
  }
  catalog_grants = {
    (dependency.unity_catalog_groups.outputs.group_display_names["workspace_admins"]) = ["ALL_PRIVILEGES"]
    (dependency.unity_catalog_groups.outputs.group_display_names["workspace_users"])  = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
}
