provider "azurerm" {
  alias = "destination"
  features {}
  subscription_id = var.destination_subscription_id
}

data "azurerm_virtual_network" "destination" {
  provider            = azurerm.destination
  name                = var.destination_vnet_name
  resource_group_name = var.destination_resource_group_name
}

# ============================================================================
# VNet Peering: Source -> Destination (default/source-subscription provider)
# ============================================================================

resource "azurerm_virtual_network_peering" "source_to_destination" {
  name                      = var.source_to_destination_peering_name
  resource_group_name       = var.source_resource_group_name
  virtual_network_name      = var.source_vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.destination.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways

  lifecycle {
    prevent_destroy = false
  }
}

# ============================================================================
# VNet Peering: Destination -> Source (aliased destination-subscription provider)
# ============================================================================

resource "azurerm_virtual_network_peering" "destination_to_source" {
  provider = azurerm.destination

  name                      = var.destination_to_source_peering_name
  resource_group_name       = var.destination_resource_group_name
  virtual_network_name      = var.destination_vnet_name
  remote_virtual_network_id = var.source_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = false

  lifecycle {
    prevent_destroy = false
  }
}
