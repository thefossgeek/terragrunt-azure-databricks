prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/vnet"
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

  address_space = values.address_space
  subnets       = values.subnets

  # Optional: a spoke sets this to its hub's DNS resolver inbound endpoint
  # IP so its resources resolve hub-centralized private zones without the
  # spoke ever linking to those zones directly. Left unset (default []),
  # this VNet just uses Azure-provided DNS - the hub's own VNet doesn't
  # need this itself, since it's already the one every zone is linked to.
  dns_servers = try(values.dns_servers, [])
}
