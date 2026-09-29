variable "name" {
  description = "Databricks workspace name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy Databricks and its own storage/Key Vault into (the \"databricks\" layer's RG)."
  type        = string
}

variable "managed_resource_group_name" {
  description = "Name for the Databricks-managed resource group (Azure creates this automatically alongside the workspace; naming it explicitly lets Terraform construct the DBFS storage account's resource ID in the same apply)."
  type        = string
}

variable "sku" {
  description = "Databricks workspace SKU."
  type        = string
  default     = "premium"

  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "sku must be one of: standard, premium or trial."
  }
}

# ---------------------------------------------------------------------------
# Network — VNet injection + private endpoints. All IDs/names come from
# terraform/vnet and terraform/network-security-group's outputs.
# ---------------------------------------------------------------------------

variable "virtual_network_id" {
  description = "ID of the EXISTING VNet for VNet injection (created by terraform/vnet)."
  type        = string
}

variable "databricks_public_subnet_name" {
  description = "Name of the EXISTING databricks-public subnet (created by terraform/vnet)."
  type        = string
}

variable "databricks_private_subnet_name" {
  description = "Name of the EXISTING databricks-private subnet (created by terraform/vnet)."
  type        = string
}

variable "databricks_public_subnet_nsg_association_id" {
  description = "ID of the EXISTING databricks-public subnet<->NSG association (created by terraform/network-security-group). Databricks requires this explicitly in custom_parameters — it won't discover the NSG on its own."
  type        = string
}

variable "databricks_private_subnet_nsg_association_id" {
  description = "ID of the EXISTING databricks-private subnet<->NSG association (created by terraform/network-security-group)."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for every private endpoint this module creates (workspace UI/API, browser-auth, backend, DBFS blob/dfs, storage blob/dfs, Key Vault) — the shared private-endpoints subnet."
  type        = string
}

variable "dns_zone_id_databricks" {
  description = "ID of the EXISTING privatelink.azuredatabricks.net zone (created by terraform/private-dns-zone)."
  type        = string
}

variable "dns_zone_id_storage_blob" {
  description = "ID of the EXISTING privatelink.blob.core.windows.net zone (created by terraform/private-dns-zone)."
  type        = string
}

variable "dns_zone_id_storage_dfs" {
  description = "ID of the EXISTING privatelink.dfs.core.windows.net zone (created by terraform/private-dns-zone)."
  type        = string
}

variable "dns_zone_id_key_vault" {
  description = "ID of the EXISTING privatelink.vaultcore.azure.net zone (created by terraform/private-dns-zone)."
  type        = string
}

# ---------------------------------------------------------------------------
# Hardened defaults
# ---------------------------------------------------------------------------

variable "no_public_ip" {
  description = "Disable public IP for compute resources."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the workspace endpoint."
  type        = bool
  default     = false
}

variable "infrastructure_encryption_enabled" {
  description = "Enable infrastructure encryption for the workspace."
  type        = bool
  default     = true
}

variable "network_security_group_rules_required" {
  description = "NSG rules mode required by Databricks — NoAzureDatabricksRules means we own and control all NSG rules; Databricks cannot inject or override them."
  type        = string
  default     = "NoAzureDatabricksRules"

  validation {
    condition     = contains(["AllRules", "NoAzureDatabricksRules"], var.network_security_group_rules_required)
    error_message = "network_security_group_rules_required must be AllRules or NoAzureDatabricksRules."
  }
}

# ---------------------------------------------------------------------------
# Compliance / Enhanced Security Add-On — compliance_security_profile_enabled
# is PERMANENT once true; cannot be disabled without destroying the workspace.
# ---------------------------------------------------------------------------

variable "compliance_security_profile_enabled" {
  description = "Enable the Databricks Compliance Security Profile. WARNING: permanent once enabled — cannot be disabled without destroying the workspace. Requires Premium SKU."
  type        = bool
  default     = false
}

variable "compliance_security_profile_standards" {
  description = "Compliance standards when the profile is enabled. Valid values: HIPAA, PCI_DSS, NONE."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for s in var.compliance_security_profile_standards : contains(["HIPAA", "PCI_DSS", "NONE"], s)])
    error_message = "compliance_security_profile_standards values must be one of: HIPAA, PCI_DSS, NONE."
  }
}

variable "enhanced_security_monitoring_enabled" {
  description = "Enable enhanced security monitoring (part of the Compliance Security Add-On)."
  type        = bool
  default     = false
}

variable "automatic_cluster_update_enabled" {
  description = "Enable automatic cluster runtime updates (part of the Compliance Security Add-On)."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# DBFS root storage hardening
# ---------------------------------------------------------------------------

variable "managed_dbfs_storage_account_name" {
  description = "Name for the Databricks-managed DBFS root storage account. Must be 3-24 lowercase alphanumeric characters."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.managed_dbfs_storage_account_name))
    error_message = "managed_dbfs_storage_account_name must be 3-24 lowercase letters and numbers only."
  }
}

variable "managed_dbfs_storage_sku_name" {
  description = "SKU for the Databricks-managed DBFS root storage account. Standard_ZRS survives an availability-zone outage within the region."
  type        = string
  default     = "Standard_ZRS"

  validation {
    condition     = contains(["Premium_LRS", "Standard_GRS", "Standard_GZRS", "Standard_LRS", "Standard_RAGRS", "Standard_RAGZRS", "Standard_ZRS"], var.managed_dbfs_storage_sku_name)
    error_message = "managed_dbfs_storage_sku_name must be a valid Azure Storage SKU."
  }
}

variable "enable_dbfs_storage_firewall" {
  description = "Enable the workspace-level storage firewall on the Databricks-managed DBFS root storage account, via a dedicated Access Connector. Defense-in-depth on top of the DBFS private endpoints — a Deny Assignment on the Databricks-managed resource group blocks direct azurerm_storage_account_network_rules, so this must go through the workspace resource itself."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Access connectors
# ---------------------------------------------------------------------------

variable "access_connector_name" {
  description = "Name for the main Databricks Access Connector (external ADLS grants)."
  type        = string
}

variable "workspace_storage_access_connector_name" {
  description = "Name for the DBFS-firewall-dedicated Access Connector. Only created when enable_dbfs_storage_firewall is true."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Main ADLS Gen2 data lake — separate from the DBFS root and from Unity
# Catalog's own dedicated storage (terraform/unity-catalog). This is the
# workspace's general-purpose data lake.
# ---------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Name for the main ADLS Gen2 data lake storage account (3-24 lowercase alphanumeric characters)."
  type        = string
}

variable "storage_account_replication_type" {
  description = "Replication SKU. ZRS survives an availability-zone outage within the region; GZRS/RA-GZRS additionally geo-replicate to the paired region. Use LRS in regions with no Availability Zones (e.g. uaecentral)."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be a valid Azure Storage replication SKU suffix."
  }
}

variable "storage_containers" {
  description = "ADLS Gen2 container names to create."
  type        = list(string)
  default     = ["raw", "curated"]
}

# ---------------------------------------------------------------------------
# Databricks' own dedicated Key Vault — created here, not looked up. Not
# shared with any other consumer — Key Vault RBAC grants the whole vault,
# not per-secret, so a shared vault would mean another consumer's group
# could technically read Databricks' secrets, and vice versa.
# ---------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Name for Databricks' own dedicated Key Vault (3-24 characters, alphanumeric and hyphens, globally unique)."
  type        = string
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "key_vault_tf_contrib_group_id" {
  description = "Object ID of the Entra ID group granted Key Vault Crypto/Secrets/Certificates Officer roles — the admin group that manages keys/secrets/certificates day to day."
  type        = string
}

# ---------------------------------------------------------------------------
# Databricks access — two groups, humans only. reader/contributor each get
# least-privilege roles across Key Vault and the workspace resource itself
# (see 04-access.tf). The reader group also doubles as the Databricks secret
# scope ACL principal (terraform/databricks-secret-acl) — reading a secret's
# value from a notebook via dbutils.secrets.get() is still a "read". Empty
# members list skips creating that group entirely.
# ---------------------------------------------------------------------------

variable "reader_group_name" {
  description = "Display name for the read-only Entra ID group (Key Vault Secrets User, Reader on the workspace)."
  type        = string
}

variable "reader_group_members" {
  description = "UPNs of humans in the reader group. Empty list skips creating the group."
  type        = list(string)
  default     = []
}

variable "contributor_group_name" {
  description = "Display name for the read-write Entra ID group (Key Vault Secrets Officer, Contributor on the workspace)."
  type        = string
}

variable "contributor_group_members" {
  description = "UPNs of humans in the contributor group. Empty list skips creating the group."
  type        = list(string)
  default     = []
}

variable "reader_roles" {
  description = "Role name per scope granted to the reader group. Keys must be key_vault and/or workspace."
  type        = map(string)
}

variable "contributor_roles" {
  description = "Role name per scope granted to the contributor group. Keys must be key_vault and/or workspace."
  type        = map(string)
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Resource ID of the EXISTING Log Analytics workspace for diagnostic settings (created by terraform/log-analytics-workspace)."
  type        = string
}

variable "alert_email" {
  description = "Email address that receives platform monitoring alerts (storage availability, etc.)."
  type        = string
  default     = "platform@example.com"
}
