locals {
  resolver_name = "dnspr-${var.location_code}-${var.environment}-${var.project}-${var.instance}"
}

resource "azurerm_private_dns_resolver" "this" {
  name                = local.resolver_name
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = var.virtual_network_id
  tags                = var.tags
}

# Inbound only: this lets other VNets (spokes, on-prem via a future gateway)
# resolve zones linked to this VNet. Outbound endpoints/forwarding rulesets
# are the opposite direction (this VNet resolving external DNS) and aren't
# needed for the hub-centralized-zones use case this module exists for.
resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  name                    = "in-${local.resolver_name}"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location
  tags                    = var.tags

  ip_configurations {
    subnet_id                    = var.inbound_subnet_id
    private_ip_allocation_method = var.inbound_endpoint_private_ip != null ? "Static" : "Dynamic"
    private_ip_address           = var.inbound_endpoint_private_ip
  }
}
