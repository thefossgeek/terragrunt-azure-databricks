# Workspace IP access lists. enableIpAccessLists is a workspace-conf toggle,
# not a first-class resource - databricks_ip_access_list requires it enabled
# first, hence the explicit depends_on below (mirrors the provider's own
# example for this resource).
#
# This module is the sole owner of the "enableIpAccessLists" key.
# modules/unity-catalog also manages its own, separate databricks_workspace_conf
# resource against the same workspace-conf object (different keys, e.g.
# enableResultsDownloading) - that's safe only because each resource's
# custom_config lists disjoint keys. Don't add "enableIpAccessLists" to any
# other databricks_workspace_conf resource in this repo.

resource "databricks_workspace_conf" "this" {
  provider = databricks.workspace

  custom_config = {
    "enableIpAccessLists" = var.enabled ? "true" : "false"
  }
}

resource "databricks_ip_access_list" "allow" {
  for_each = var.allow_rules
  provider = databricks.workspace

  label        = each.value.label
  list_type    = "ALLOW"
  ip_addresses = each.value.ip_addresses

  depends_on = [databricks_workspace_conf.this]
}

resource "databricks_ip_access_list" "block" {
  for_each = var.block_rules
  provider = databricks.workspace

  label        = each.value.label
  list_type    = "BLOCK"
  ip_addresses = each.value.ip_addresses

  depends_on = [databricks_workspace_conf.this]
}
