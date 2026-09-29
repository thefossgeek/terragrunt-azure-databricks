prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules//unity-catalog-groups"
}

locals {
  groups = yamldecode(file("${dirname(find_in_parent_folders("root.hcl"))}/data/unity-catalog-groups.yaml"))
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  groups = local.groups.groups
}
