# The admin/user Entra ID groups themselves are created in the separate
# terraform/unity-catalog-groups stack (applied before this one) — not here.
# workspace_permission_assignments/catalog_grants below just reference those
# groups by display name.

variable "workspace_numeric_id" {
  description = "Databricks workspace numeric ID."
  type        = string
}

variable "catalog_name" {
  description = "Catalog to grant privileges on."
  type        = string
}

variable "workspace_permission_assignments" {
  description = "Group display name -> workspace permission (ADMIN or USER)."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for p in values(var.workspace_permission_assignments) : contains(["ADMIN", "USER"], p)])
    error_message = "workspace_permission_assignments values must be ADMIN or USER."
  }
}

variable "catalog_grants" {
  description = "Group display name -> catalog privileges (e.g. [\"USE_CATALOG\", \"SELECT\"])."
  type        = map(list(string))
  default     = {}
}
