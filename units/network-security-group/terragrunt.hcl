prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/network-security-group"
}

locals {
  # Convention: rules/ always sits next to root.hcl at the stack root.
  rules_dir = "${dirname(find_in_parent_folders("root.hcl"))}/rules"
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  project  = values.project
  instance = values.instance

  resource_group_name = dependency.resource_groups.outputs.resource_groups["network"].name

  # values.nsg_rules_files: map of subnet key (must match a key in the vnet
  # dependency's `subnets` output) -> rules yaml filename under rules_dir.
  # One NSG per entry, associated with the like-named subnet.
  network_security_groups = {
    for key, rules_file in values.nsg_rules_files : key => {
      subnet_id      = dependency.vnet.outputs.subnets[key].id
      security_rules = yamldecode(file("${local.rules_dir}/${rules_file}"))
    }
  }
}
