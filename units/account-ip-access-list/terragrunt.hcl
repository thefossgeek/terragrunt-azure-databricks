prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/account-ip-access-list"
}

inputs = {
  subscription_id       = values.subscription_id
  tenant_id             = values.tenant_id
  location              = values.location
  location_code         = values.location_code
  environment           = values.environment
  tags                  = values.tags
  databricks_account_id = values.databricks_account_id

  network_policy_id = try(values.network_policy_id, "default-policy")

  enabled     = values.enabled
  allow_rules = values.allow_rules
  block_rules = try(values.block_rules, {})
}
