prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/vnet-peering"
}

inputs = {
  subscription_id = values.subscription_id
  tenant_id       = values.tenant_id
  location        = values.location
  location_code   = values.location_code
  environment     = values.environment
  tags            = values.tags

  destination_subscription_id = values.hub_subscription_id

  source_to_destination_peering_name = "peer-${dependency.source.outputs.vnet_name}-to-${values.destination_vnet_name}"
  destination_to_source_peering_name = "peer-${values.destination_vnet_name}-to-${dependency.source.outputs.vnet_name}"

  source_resource_group_name = dependency.resource_groups.outputs.resource_groups["network"].name
  source_vnet_name           = dependency.source.outputs.vnet_name
  source_vnet_id             = dependency.source.outputs.vnet_id

  destination_resource_group_name = values.destination_resource_group_name
  destination_vnet_name           = values.destination_vnet_name

  allow_forwarded_traffic = values.allow_forwarded_traffic
  allow_gateway_transit   = values.allow_gateway_transit
  use_remote_gateways     = values.use_remote_gateways

  # Deliberately NOT populated from dependency.dns_zones. That output would
  # feed this module's destination-links-to-source-zones DNS link, which
  # here would mean linking the *spoke* VNet directly to the hub's
  # centralized zones - the exact anti-pattern the hub's single-source-of
  # -truth design avoids (Azure landing zone guidance: zones link only to
  # the hub VNet, never to individual spokes). The dependency is still
  # declared below purely to order this unit after the hub's zones and
  # keep the relationship explicit; spoke-side resolution of hub-owned
  # zones is meant to come from a DNS forwarder in the hub (Azure Private
  # DNS Resolver or Firewall DNS proxy) once one exists, not from a link
  # here.
  source_private_dns_zone_names = []
}
