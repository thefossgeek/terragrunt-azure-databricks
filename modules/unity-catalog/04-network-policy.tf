# ── Serverless egress control (NCC + Account Network Policy) ───────────────────
# Databricks serverless compute (serverless SQL warehouses, serverless jobs/
# notebooks) does not run inside this workspace's VNet — it bypasses the NSG
# deny-internet-egress rule and UDR entirely. The only way to restrict its
# internet access is at the Databricks account level: a Network Connectivity
# Config (NCC) bound to the workspace, paired with an Account Network Policy in
# RESTRICTED_ACCESS mode that allow-lists specific destinations (or none at all).
#
# When enabled, this also becomes the NCC used by the self-approving private
# endpoints above (ncc_dfs/ncc_blob in 03-private-endpoints.tf) — see
# local.ncc_id_effective / local.ncc_name_effective.

resource "databricks_mws_network_connectivity_config" "this" {
  count = var.create_network_connectivity_config ? 1 : 0

  provider = databricks.account
  name     = "ncc-${var.resource_suffix}"
  region   = var.location
}

resource "databricks_account_network_policy" "this" {
  count = var.create_network_connectivity_config ? 1 : 0

  provider          = databricks.account
  account_id        = var.databricks_account_id
  network_policy_id = "np-${var.resource_suffix}"

  egress = {
    network_access = {
      restriction_mode = "RESTRICTED_ACCESS"
      allowed_internet_destinations = [
        for dest in var.allowed_internet_destinations : {
          destination               = dest
          internet_destination_type = "DNS_NAME"
        }
      ]
      policy_enforcement = {
        enforcement_mode = "ENFORCED"
      }
    }
  }

  # Context-Based Ingress: restrict the workspace's public endpoint. No
  # allow_rules needed — public_network_access_enabled is already false
  # (private endpoints only), so there's no legitimate public path to
  # allow-list; this just closes it off at the account level too.
  ingress = {
    public_access = {
      restriction_mode = "RESTRICTED_ACCESS"
    }
  }
}

resource "databricks_mws_ncc_binding" "this" {
  count = var.create_network_connectivity_config ? 1 : 0

  provider                       = databricks.account
  network_connectivity_config_id = databricks_mws_network_connectivity_config.this[0].network_connectivity_config_id
  workspace_id                   = var.workspace_numeric_id
}

resource "databricks_workspace_network_option" "this" {
  count = var.create_network_connectivity_config ? 1 : 0

  provider          = databricks.account
  network_policy_id = databricks_account_network_policy.this[0].network_policy_id
  workspace_id      = var.workspace_numeric_id
}

locals {
  # Plan-time-known boolean — used for the ncc_dfs/ncc_blob module `count` in
  # 03-private-endpoints.tf. Can't use `ncc_id_effective != null` there: when
  # we create the NCC ourselves, its ID isn't known until apply, and
  # Terraform can't size a `count` off an unknown value.
  ncc_in_use = var.create_network_connectivity_config || var.ncc_id != null

  ncc_id_effective   = var.create_network_connectivity_config ? databricks_mws_network_connectivity_config.this[0].network_connectivity_config_id : var.ncc_id
  ncc_name_effective = var.create_network_connectivity_config ? databricks_mws_network_connectivity_config.this[0].name : var.ncc_name
}
