# ── Cloudflare Tunnel ─────────────────────────────────────────────────────────
# Outbound-only from the connector VM to Cloudflare's edge — nothing inbound,
# no public IP or bastion required on the Azure side.

resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id    = var.cloudflare_account_id
  name          = "tunnel-${var.resource_suffix}"
  tunnel_secret = random_id.tunnel_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_virtual_network" "this" {
  account_id         = var.cloudflare_account_id
  name               = "vnet-${var.resource_suffix}"
  comment            = "Routes to Azure spoke VNets via the ${var.resource_suffix} hub connector"
  is_default_network = false
}

locals {
  # Route the user-supplied spoke CIDRs AND the connector's own subnet — the
  # DNS forwarder used by fallback_domains (access_control.tf) lives in that
  # subnet, so Cloudflare needs a route to reach it too.
  tunnel_routes = concat(var.spoke_cidrs, var.connector_subnet_prefix)
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "this" {
  for_each = toset(local.tunnel_routes)

  account_id         = var.cloudflare_account_id
  network            = each.value
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.this.id
  virtual_network_id = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this.id
  comment            = "Route to ${each.value}"
}
