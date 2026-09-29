# ── Databricks workspace ──────────────────────────────────────────────────────

output "workspace_id" {
  description = "Databricks workspace resource ID."
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_name" {
  description = "Databricks workspace name."
  value       = azurerm_databricks_workspace.this.name
}

output "workspace_url" {
  description = "Databricks workspace URL — feed this to terraform/databricks-secret-acl and any Unity Catalog stack as databricks_workspace_url."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "workspace_numeric_id" {
  description = "Databricks workspace numeric ID — used for Unity Catalog metastore assignment and workspace permission assignments."
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "managed_resource_group_id" {
  description = "Managed Resource Group ID created by Databricks."
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "access_connector_id" {
  description = "Main Databricks access connector resource ID (external ADLS grants)."
  value       = azurerm_databricks_access_connector.this.id
}

# ── Networking ─────────────────────────────────────────────────────────────

output "workspace_private_endpoint_ip" {
  description = "Private IP of the workspace UI/API private endpoint."
  value       = azurerm_private_endpoint.workspace_ui_api.private_service_connection[0].private_ip_address
}

# ── Storage (main ADLS Gen2 data lake) ────────────────────────────────────────

output "storage_account_id" {
  description = "Resource ID of the main ADLS Gen2 data lake storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the main ADLS Gen2 data lake storage account."
  value       = azurerm_storage_account.this.name
}

# ── Key Vault ──────────────────────────────────────────────────────────────

output "key_vault_id" {
  description = "Resource ID of Databricks' own dedicated Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of Databricks' own dedicated Key Vault."
  value       = azurerm_key_vault.this.name
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP of the Key Vault's private endpoint."
  value       = azurerm_private_endpoint.key_vault.private_service_connection[0].private_ip_address
}

# ── Access groups ──────────────────────────────────────────────────────────

output "reader_group_object_id" {
  description = "Object ID of the reader Entra ID group, if created (null when reader_group_members is empty)."
  value       = try(azuread_group.reader[0].object_id, null)
}

output "reader_group_display_name" {
  description = "Display name of the reader Entra ID group, if created — terraform/databricks-secret-acl uses this as the secret scope ACL's principal."
  value       = try(azuread_group.reader[0].display_name, null)
}

output "contributor_group_object_id" {
  description = "Object ID of the contributor Entra ID group, if created (null when contributor_group_members is empty)."
  value       = try(azuread_group.contributor[0].object_id, null)
}

# ── Monitoring ─────────────────────────────────────────────────────────────

output "action_group_id" {
  description = "Resource ID of the platform alerts action group."
  value       = azurerm_monitor_action_group.this.id
}
