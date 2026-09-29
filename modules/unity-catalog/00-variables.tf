# ── Naming ────────────────────────────────────────────────────────────────────

variable "resource_suffix" {
  description = "Suffix used to name all Unity Catalog Azure and Databricks resources (e.g. uc-eus-prd-alphaai-001)."
  type        = string
}

# ── Azure ─────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Resource group where the dedicated UC storage account, Access Connector, and private endpoints are created (the \"databricks\" layer's RG)."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints on the dedicated UC storage account (the shared private-endpoints subnet)."
  type        = string
}

variable "dns_zone_ids" {
  description = "Private DNS zone IDs for private endpoint resolution. Required keys: blob, dfs."
  type        = map(string)
}

variable "storage_account_replication_type" {
  description = "Replication type for the dedicated Unity Catalog storage account. ZRS survives an availability-zone outage within the region; GZRS/RA-GZRS additionally geo-replicate to the region's paired region for DR."
  type        = string
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be a valid Azure Storage replication SKU suffix."
  }
}

variable "storage_container_name" {
  description = "Container name inside the dedicated Unity Catalog storage account."
  type        = string
  default     = "unitycatalog"
}

# ── Data ADLS (raw / curated) ─────────────────────────────────────────────────

variable "data_storage_account_id" {
  description = "Resource ID of the data ADLS Gen2 storage account (raw, curated containers) — the main data lake created by terraform/databricks."
  type        = string
}

variable "data_storage_account_name" {
  description = "Name of the data ADLS Gen2 storage account used for raw and curated external locations."
  type        = string
}

variable "data_storage_containers" {
  description = "Container names on the data ADLS Gen2 to register as Unity Catalog External Locations."
  type        = list(string)
  default     = ["raw", "curated"]
}

# ── Databricks ────────────────────────────────────────────────────────────────

variable "workspace_numeric_id" {
  description = "Databricks workspace numeric ID — output from terraform/databricks."
  type        = string
}

variable "metastore_name" {
  description = "Unity Catalog metastore display name."
  type        = string
}

variable "catalog_name" {
  description = "Name of the Unity Catalog catalog. Managed tables created here land in customer storage."
  type        = string
  default     = "main"
}

variable "force_destroy" {
  description = "When true, destroys non-empty catalogs, external locations, and storage credentials. Required at creation time; cannot be set retroactively."
  type        = bool
  default     = false
}

variable "catalog_isolation_mode" {
  description = "Catalog isolation mode. ISOLATED restricts access to this workspace only; OPEN allows sharing across workspaces."
  type        = string
  default     = "ISOLATED"

  validation {
    condition     = contains(["ISOLATED", "OPEN"], var.catalog_isolation_mode)
    error_message = "catalog_isolation_mode must be ISOLATED or OPEN."
  }
}

variable "is_default_namespace" {
  description = "If true, sets this catalog as the default namespace so sessions resolve unqualified table references to it."
  type        = bool
  default     = true
}

# ── NCC (serverless compute) ──────────────────────────────────────────────────

variable "ncc_id" {
  description = "ID of an EXISTING Network Connectivity Configuration to reuse. Ignored when create_network_connectivity_config is true (this module creates and owns its own NCC instead). Leave null if serverless is not in use and you're not creating one here either."
  type        = string
  default     = null
}

variable "ncc_name" {
  description = "Name of an existing Network Connectivity Configuration to reuse (used in private endpoint connection descriptions). Ignored when create_network_connectivity_config is true."
  type        = string
  default     = ""
}

variable "create_network_connectivity_config" {
  description = "Create a Network Connectivity Config + Account Network Policy (RESTRICTED_ACCESS) and bind both to this workspace, restricting serverless compute's internet egress to allowed_internet_destinations. Serverless compute bypasses the workspace VNet entirely, so this is the only lever that controls its internet access."
  type        = bool
  default     = false
}

variable "allowed_internet_destinations" {
  description = "FQDNs serverless compute is allowed to reach when create_network_connectivity_config is true (e.g. an internal package-mirror hostname). Empty list means no internet egress at all — the most isolated posture."
  type        = list(string)
  default     = []
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to create an NCC private endpoint rule for (group_id=\"vault\"), letting serverless compute reach it directly (e.g. code calling the Key Vault SDK instead of dbutils.secrets.get(), which is already control-plane-mediated and doesn't need this). Leave null to skip — not needed unless something on serverless calls Key Vault directly."
  type        = string
  default     = null
}

# ── Workspace admin hardening ─────────────────────────────────────────────────

variable "enable_workspace_hardening" {
  description = "Disable notebook results download/export/clipboard-copy, the DBFS file browser, and the data-upload UI; enforce user isolation and verbose audit logs; store notebook results in customer storage rather than Databricks-internal. Reduces the data-exfiltration surface via the workspace UI."
  type        = bool
  default     = false
}

# ── Entra ID group-based access control ───────────────────────────────────────
# Workspace permission assignments and catalog grants live in the separate
# modules/unity-catalog-access module instead — they depend on Entra ID
# groups being resolvable by Databricks (which can lag group creation; see
# that module's notes), and keeping that dependency out of this module means
# the metastore/storage/catalog/hardening resources here never get blocked by
# group-provisioning timing.

# ── Catalog/metastore owner — group, not an individual user ───────────────────
# The group itself is created by the separate unity-catalog-groups unit
# (07-unity-catalog-groups, applied before this one) — not here. Databricks'
# Automatic Identity Management needs real wall-clock time to pull a
# brand-new Entra ID group before it's resolvable as an owner; splitting the
# group into its own, earlier-applied unit gives it that time, same reasoning
# as modules/unity-catalog-access's group lookups.

variable "owner_group_name" {
  description = "Catalog/metastore owner group display name. Null keeps the default owner."
  type        = string
  default     = null
}
