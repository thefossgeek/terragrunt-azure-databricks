# ── Databricks' own dedicated Key Vault ──────────────────────────────────────
# Not shared with any other consumer — Key Vault RBAC, network access via
# private endpoint only.

resource "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = var.key_vault_sku_name

  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enabled_for_disk_encryption   = true
  public_network_access_enabled = false
  rbac_authorization_enabled    = true

  tags = var.tags
}

# ── Admin access — Terraform/operator group manages keys/secrets/certs ──────

locals {
  key_vault_tf_contrib_roles = {
    crypto_officer       = "Key Vault Crypto Officer"
    secrets_officer      = "Key Vault Secrets Officer"
    certificates_officer = "Key Vault Certificates Officer"
  }
}

resource "azurerm_role_assignment" "key_vault_tf_contrib" {
  for_each = local.key_vault_tf_contrib_roles

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value
  principal_id         = var.key_vault_tf_contrib_group_id
}

# ── Private endpoint ─────────────────────────────────────────────────────────

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${var.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-vault"
    private_dns_zone_ids = [var.dns_zone_id_key_vault]
  }
}
