# ── Entra ID group — Zero Trust access, not individual users ─────────────────

resource "azuread_group" "zero_trust_access" {
  display_name     = var.access_group_name
  security_enabled = true
  members          = var.access_group_members
}

# ── Device Enrollment Permissions ────────────────────────────────────────────
# Cloudflare represents "who's allowed to enroll a device at all" as a special
# Access Application of type "warp". Without this, WARP enrollment fails with
# "Unable to find your Access application!" regardless of the IdP/device
# profile/Gateway policy being configured correctly.

resource "cloudflare_zero_trust_access_application" "warp_enrollment" {
  account_id = var.cloudflare_account_id
  # Cloudflare auto-provisions this app per-account with a fixed name
  # ("Warp Login App") and doesn't actually persist a rename via the API —
  # matching it here (plus lifecycle.ignore_changes below) avoids a perpetual
  # diff on every plan/apply.
  name                      = "Warp Login App"
  type                      = "warp"
  session_duration          = "24h"
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.entra_id.id]
  auto_redirect_to_identity = false

  policies = [{
    name     = "allow-${var.access_group_name}"
    decision = "allow"
    include = [{
      azure_ad = {
        id                   = azuread_group.zero_trust_access.object_id
        identity_provider_id = cloudflare_zero_trust_access_identity_provider.entra_id.id
      }
    }]
  }]

  lifecycle {
    ignore_changes = [name]
  }
}

# ── WARP device profile ──────────────────────────────────────────────────────
# Scoped to members of the access group. include = split-tunnel routes pushed
# to enrolled devices; fallback_domains = private-endpoint hostnames resolved
# via the connector VM's local DNS forwarder instead of Cloudflare's resolver.

resource "cloudflare_zero_trust_device_custom_profile" "this" {
  account_id  = var.cloudflare_account_id
  name        = "profile-${var.resource_suffix}"
  description = "Routes spoke VNet CIDRs through the private hub tunnel"
  # Match by group ID, not name — Entra ID's group claims surface as object
  # IDs, not display names, so identity.groups.name is empty and never
  # matches regardless of actual membership.
  match      = "any(identity.groups.id[*] in {\"${azuread_group.zero_trust_access.object_id}\"})"
  precedence = 100
  enabled    = true

  service_mode_v2 = {
    mode = "warp"
  }
  tunnel_protocol = "wireguard"

  # Must match the tunnel's own routes (tunnel.tf's local.tunnel_routes =
  # spoke_cidrs + the hub's own subnet) — a tunnel route alone only tells
  # Cloudflare's edge how to reach a CIDR; the client only routes a CIDR
  # through WARP at all if it's also listed here.
  include = [
    for cidr in local.tunnel_routes : {
      address     = cidr
      description = "spoke"
    }
  ]
}

# fallback_domains is read-only on cloudflare_zero_trust_device_custom_profile
# in the provider (computed-only, no "optional" flag) — it has to be pushed
# through the API directly. Re-runs whenever the domain list or the
# connector's IP changes.
locals {
  fallback_domain_entries = [
    for domain in var.private_dns_forward_domains : {
      suffix      = domain
      description = "Resolve via the hub connector private DNS forwarder"
      dns_server  = [azurerm_network_interface.connector.private_ip_address]
    }
  ]
}

resource "null_resource" "fallback_domains" {
  triggers = {
    payload = jsonencode(local.fallback_domain_entries)
  }

  # Values are passed via environment, not interpolated into the command
  # string — avoids shell-quoting breakage from special characters (quotes,
  # apostrophes, etc.) in any of the JSON content.
  provisioner "local-exec" {
    command = "${path.module}/scripts/update-fallback-domains.sh"
    environment = {
      CF_ACCOUNT_ID = var.cloudflare_account_id
      CF_POLICY_ID  = cloudflare_zero_trust_device_custom_profile.this.policy_id
      CF_PAYLOAD    = jsonencode(local.fallback_domain_entries)
    }
  }

  depends_on = [cloudflare_zero_trust_device_custom_profile.this]
}

# ── Gateway network policy ───────────────────────────────────────────────────
# The actual Zero Trust gate: only members of the access group may route
# traffic to the spoke CIDRs at all.

resource "cloudflare_zero_trust_gateway_policy" "allow_private_access" {
  account_id  = var.cloudflare_account_id
  name        = "gw-${var.resource_suffix}-allow-private"
  description = "Allow spoke VNet access only for the ${var.access_group_name} group"
  enabled     = true
  action      = "allow"
  precedence  = 100
  filters     = ["l4"]

  # net.dst.ip is a scalar field (no any() wrapper — that's only for array
  # fields like identity.groups.id[*] below). Match by group ID, not name —
  # see the same note on the device profile's match field above.
  traffic  = "net.dst.ip in {${join(" ", local.tunnel_routes)}}"
  identity = "any(identity.groups.id[*] in {\"${azuread_group.zero_trust_access.object_id}\"})"
}
