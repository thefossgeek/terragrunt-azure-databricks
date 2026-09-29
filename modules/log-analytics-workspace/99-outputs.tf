output "id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "Workspace (customer) ID — the GUID diagnostic settings/agents reference, distinct from the resource ID. Not a secret."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "principal_id" {
  description = "Principal (object) ID of the workspace's system-assigned managed identity. Grant this RBAC roles on whatever it needs to reach — never a shared key."
  value       = azurerm_log_analytics_workspace.this.identity[0].principal_id
}
