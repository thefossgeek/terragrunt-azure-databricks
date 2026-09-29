variable "network_connectivity_config_id" {
  description = "ID of the Network Connectivity Configuration to create the private endpoint rule under."
  type        = string
}

variable "network_connectivity_config_name" {
  description = "Human-readable NCC name — only used in the approval description string."
  type        = string
  default     = ""
}

variable "databricks_account_id" {
  description = "Databricks account UUID."
  type        = string
}

variable "group_id" {
  description = "Sub-resource group ID of the target Azure resource (e.g. blob or dfs for storage)."
  type        = string
}

variable "resource_id" {
  description = "ARM resource ID of the target Azure resource (e.g. a storage account ID)."
  type        = string
}

variable "data_api_type" {
  description = "AzAPI resource type used to read back the pending PE connections."
  type        = string
  default     = "Microsoft.Storage/storageAccounts@2024-01-01"
}

variable "update_api_type" {
  description = "AzAPI resource type used to approve the PE connection."
  type        = string
  default     = "Microsoft.Storage/storageAccounts/privateEndpointConnections@2024-01-01"
}
