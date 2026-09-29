prevent_destroy = false

# Requires CLOUDFLARE_API_TOKEN in the environment when you run terragrunt —
# the provider is generated with no inline credentials (see root.hcl).
include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/cloudflare-zero-trust"
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  resource_suffix = values.resource_suffix

  cloudflare_account_id = values.cloudflare_account_id
  cloudflare_team_name  = values.cloudflare_team_name

  # Existing hub network (02environments/hub's 01resource-groups/02vnet
  # units) — this module never creates its own VNet/subnet, it deploys into
  # the "cloudflare-zero-trust" subnet already carved out there.
  resource_group_name     = dependency.resource_groups.outputs.resource_groups["network"].name
  subnet_id               = dependency.vnet.outputs.subnets["cloudflare-zero-trust"].id
  connector_subnet_prefix = dependency.vnet.outputs.subnets["cloudflare-zero-trust"].address_prefixes

  spoke_cidrs = values.spoke_cidrs

  private_dns_forward_domains = values.private_dns_forward_domains

  access_group_name    = values.access_group_name
  access_group_members = values.access_group_members
}
