
locals {
  routes = merge([
    for rt_key, rt in var.route_tables : merge(
      { for route in rt.routes : "${rt_key}.${route.name}" => merge(route, { rt_key = rt_key }) },
      rt.enable_firewall_egress ? {
        "${rt_key}.default-egress-via-firewall" = {
          name                   = "default-egress-via-firewall"
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = rt.firewall_private_ip
          rt_key                 = rt_key
        }
      } : {}
    )
  ]...)
}

resource "azurerm_route_table" "this" {
  for_each = var.route_tables

  name                = coalesce(each.value.name, "rt-${var.location_code}-${var.environment}-${var.project}-${each.key}-${var.instance}")
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_route" "this" {
  for_each = local.routes

  name                   = each.value.name
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.rt_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_type == "VirtualAppliance" ? each.value.next_hop_in_ip_address : null
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = { for key, rt in var.route_tables : key => rt if rt.subnet_id != null }

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.this[each.key].id

  depends_on = [azurerm_route.this]
}
