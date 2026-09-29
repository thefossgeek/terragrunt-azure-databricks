prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/route-table"
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

  # values.route_table_subnet_keys: subnet keys (must match keys in the
  # vnet dependency's `subnets` output) that each get their own route
  # table, associated with the like-named subnet.
  route_tables = {
    for key in values.route_table_subnet_keys : key => {
      subnet_id              = dependency.vnet.outputs.subnets[key].id
      enable_firewall_egress = values.enable_firewall_egress
      firewall_private_ip    = values.firewall_private_ip
    }
  }
}
