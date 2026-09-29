# ============================================================================
# Destination subscription (aliased provider)
# ============================================================================

variable "destination_subscription_id" {
  type        = string
  description = "Subscription ID the destination VNet lives in. Can be the same as the source's, or a different one entirely."
}

# ============================================================================
# Peering names
# ============================================================================

variable "source_to_destination_peering_name" {
  type        = string
  description = "Name for the peering created on the source VNet, pointing at the destination (e.g. peer-source-to-destination)."
}

variable "destination_to_source_peering_name" {
  type        = string
  description = "Name for the peering created on the destination VNet, pointing back at the source (e.g. peer-destination-to-source)."
}

# ============================================================================
# Source VNet — passed in directly (typically from a terragrunt dependency,
# since this is usually a stack this same repo/pipeline already manages)
# ============================================================================

variable "source_resource_group_name" {
  type        = string
  description = "Resource group of the source VNet."
}

variable "source_vnet_name" {
  type        = string
  description = "Name of the source VNet."
}

variable "source_vnet_id" {
  type        = string
  description = "Resource ID of the source VNet — needed as the remote_virtual_network_id for the destination side's peering."
}

# ============================================================================
# Destination VNet — looked up via data source, NOT passed in as an ID.
# The destination (e.g. a hub) may be managed by a different team, pipeline,
# or subscription entirely — a data source lookup by name avoids coupling
# this stack to another terragrunt stack's state/outputs.
# ============================================================================

variable "destination_resource_group_name" {
  type        = string
  description = "Resource group of the EXISTING destination VNet."
}

variable "destination_vnet_name" {
  type        = string
  description = "Name of the EXISTING destination VNet — looked up via data source, not passed in as an ID."
}

# ============================================================================
# Peering options
# ============================================================================

variable "allow_forwarded_traffic" {
  type        = bool
  description = "Allow forwarded traffic on both sides of the peering (needed if the destination routes traffic through a firewall/NVA)."
  default     = true
}

variable "allow_gateway_transit" {
  type        = bool
  description = "Allow the destination to provide gateway transit (VPN/ExpressRoute) to the source."
  default     = false
}

variable "use_remote_gateways" {
  type        = bool
  description = "Allow the source to use the destination's gateway."
  default     = false
}

# ============================================================================
# DNS: link the destination VNet to the source's existing private DNS zones
# ============================================================================
# Peering alone only opens the network path. A DNS query issued from the
# destination is resolved based on which VNet the query
# originates from — without this link, it still returns the source's
# public IP. Optional: leave the list empty if the destination never needs
# to privately resolve anything in the source VNet.

variable "source_private_dns_zone_names" {
  type        = list(string)
  description = "Names of EXISTING private DNS zones in the source's resource group to link to the destination VNet (e.g. privatelink.blob.core.windows.net). Leave empty to skip."
  default     = []
}

