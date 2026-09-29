prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/log-analytics-workspace"
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  name = values.name

  resource_group_name = dependency.resource_groups.outputs.resource_groups["monitoring"].name

  retention_in_days = values.retention_in_days
  daily_quota_gb    = values.daily_quota_gb
}
