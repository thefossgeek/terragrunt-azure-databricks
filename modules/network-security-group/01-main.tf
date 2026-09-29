locals {
  nsg_rules = merge([
    for nsg_key, nsg in var.network_security_groups : {
      for rule in nsg.security_rules : "${nsg_key}.${rule.name}" => merge(rule, { nsg_key = nsg_key })
    }
  ]...)
}

resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = coalesce(each.value.name, "nsg-${var.location_code}-${var.environment}-${var.project}-${each.key}-${var.instance}")
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.nsg_rules

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  source_port_ranges           = each.value.source_port_ranges
  destination_port_range       = each.value.destination_port_range
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_address_prefix
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this[each.value.nsg_key].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for key, nsg in var.network_security_groups : key => nsg if nsg.subnet_id != null }

  subnet_id                 = each.value.subnet_id
  network_security_group_id = azurerm_network_security_group.this[each.key].id

  depends_on = [azurerm_network_security_rule.this]
}
