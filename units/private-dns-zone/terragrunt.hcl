prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/private-dns-zone"
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  resource_group_name = dependency.resource_groups.outputs.resource_groups["network"].name

  # Every zone links only to this stack's own vnet dependency. This unit is
  # meant to be wired into exactly one stack - the hub/connectivity one -
  # so that link target is always the hub VNet: centralizing zone creation
  # and its VNet link in one place, per Azure landing zone guidance. Spokes
  # must not source this unit themselves; they read its `zones` output via
  # a cross-stack dependency instead.
  zones = {
    for key, name in values.zone_names : key => {
      name    = name
      vnet_id = dependency.vnet.outputs.vnet_id
    }
  }
}
