# ── Existing hub network ──────────────────────────────────────────────────────
# The hub VNet, the "cloudflare-zero-trust" subnet, and that subnet's NSG are
# all created upstream in 02environments/hub (02vnet/04nsg units) — this
# module only deploys into them via var.resource_group_name/var.subnet_id. It
# never creates its own VNet/subnet/NSG, so it stays consistent with every
# other private-endpoint-backed service in this repo that reads the hub's
# network as existing infrastructure rather than duplicating it.

# ── Outbound-only internet path — no public IP on the VM itself ─────────────
# cloudflared needs to reach Cloudflare's edge; NAT Gateway gives it that
# without exposing any inbound public endpoint.

resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.resource_suffix}-nat"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                = "nat-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "connector" {
  subnet_id      = var.subnet_id
  nat_gateway_id = azurerm_nat_gateway.this.id
}
