resource "azurerm_private_dns_zone" "this" {
  for_each = { for key, zone in var.zones : key => zone if zone.create_zone }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

data "azurerm_private_dns_zone" "this" {
  for_each = { for key, zone in var.zones : key => zone if !zone.create_zone }

  name                = each.value.name
  resource_group_name = var.resource_group_name
}

# Spoke-to-zone link: links each zone to its own (spoke) VNet — the zone's
# primary link, created here where the zone itself lives.
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.zones

  name                  = "${each.key}-${var.environment}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = each.value.vnet_id
  registration_enabled  = each.value.registration_enabled
  tags                  = var.tags

  depends_on = [azurerm_private_dns_zone.this, data.azurerm_private_dns_zone.this]
}
