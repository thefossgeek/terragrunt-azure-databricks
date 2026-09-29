# Resource in Terraform connects an Azure Private DNS Zone to an Azure Virtual Network (VNet). 
# This connection allows resources inside that specific VNet to resolve domain names managed by the Private DNS Zone

# Hub-to-zone link: links the destination (hub) VNet to zones that already
# live in the source (spoke) — lets the hub resolve the spoke's private DNS.
resource "azurerm_private_dns_zone_virtual_network_link" "destination_to_source_zones" {
  for_each = toset(var.source_private_dns_zone_names)

  name                  = "${var.destination_vnet_name}-link"
  resource_group_name   = var.source_resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = data.azurerm_virtual_network.destination.id
  registration_enabled  = false
}
