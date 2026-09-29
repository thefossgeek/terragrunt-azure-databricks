output "storage_account_id" {
  description = "ID of the dedicated Unity Catalog Azure Storage Account."
  value       = azurerm_storage_account.unity_catalog.id
}

output "access_connector_id" {
  description = "ID of the dedicated Unity Catalog Access Connector."
  value       = azurerm_databricks_access_connector.unity_catalog.id
}

output "access_connector_mi_id" {
  description = "Managed identity principal ID of the Unity Catalog Access Connector."
  value       = local.access_connector_mi_id
}

output "metastore_id" {
  description = "Unity Catalog metastore ID. Either newly created or an existing metastore discovered for var.location — see local.create_new_metastore in 02-metastore.tf."
  value       = local.metastore_id
}

output "external_location_id" {
  description = "ID of the dedicated Unity Catalog External Location."
  value       = databricks_external_location.unity_catalog.id
}

output "catalog_name" {
  description = "Name of the Unity Catalog catalog."
  value       = databricks_catalog.catalog.name
}
