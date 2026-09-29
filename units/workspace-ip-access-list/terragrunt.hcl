prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/workspace-ip-access-list"
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  # Points the "workspace" aliased databricks provider (generated in
  # root.hcl) at the actual deployed workspace - first unit in this repo to
  # populate this variable; every other unit lets it default to null since
  # they don't touch the workspace-scoped Databricks API.
  databricks_workspace_url = dependency.databricks.outputs.workspace_url

  enabled     = values.enabled
  allow_rules = values.allow_rules
  block_rules = try(values.block_rules, {})
}
