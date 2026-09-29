# ── Virtual Network — network layer, deploys into an existing resource group ──

locals {
  vnet_name = coalesce(var.vnet_name, "vnet-${var.location_code}-${var.environment}-${var.project}-${var.instance}")
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }
}
