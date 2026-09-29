output "enabled" {
  description = "Effective enableIpAccessLists setting."
  value       = var.enabled
}

output "allow_list_ids" {
  description = "Key -> databricks_ip_access_list id, for ALLOW rules."
  value       = { for key, r in databricks_ip_access_list.allow : key => r.id }
}

output "block_list_ids" {
  description = "Key -> databricks_ip_access_list id, for BLOCK rules."
  value       = { for key, r in databricks_ip_access_list.block : key => r.id }
}
