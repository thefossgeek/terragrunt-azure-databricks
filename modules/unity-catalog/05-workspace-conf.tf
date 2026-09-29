# ── Workspace admin hardening ────────────────────────────────────────────────
# Reduces the data-exfiltration surface inside the workspace UI. Lives here
# (rather than terraform/databricks) because this is the first stack in the
# apply order with a workspace-scoped databricks provider already configured
# (databricks.workspace, host = terraform/databricks's deployed workspace
# URL) — terraform/databricks can't reference that host in the same apply as
# the workspace's own creation.

resource "databricks_workspace_conf" "this" {
  count = var.enable_workspace_hardening ? 1 : 0

  provider = databricks.workspace

  # This resource doesn't reliably infer the workspace from provider host alone —
  # it needs the numeric workspace ID spelled out explicitly.
  provider_config {
    workspace_id = var.workspace_numeric_id
  }

  custom_config = {
    "enableResultsDownloading"                         = "false"
    "enableNotebookTableClipboard"                     = "false"
    "enableVerboseAuditLogs"                           = "true"
    "enableDbfsFileBrowser"                            = "false"
    "enableExportNotebook"                             = "false"
    "enforceUserIsolation"                             = "true"
    "storeInteractiveNotebookResultsInCustomerAccount" = "true"
    "enableUploadDataUis"                              = "false"
    # enableIpAccessLists is deliberately NOT set here — modules/workspace-ip-access-list
    # (unit 12-workspace-ip-access-list) is the sole owner of that key. Both
    # modules manage separate databricks_workspace_conf resources against the
    # same underlying workspace-conf object; the provider's API only patches
    # the keys each resource explicitly lists, so this is safe as long as no
    # key is ever listed in more than one place. Don't add it back here.
    # FileStore serves /FileStore (DBFS) contents over a direct HTTPS URL —
    # a data-exfiltration path outside normal workspace access controls.
    "enableFileStoreEndpoint" = "false"
    # Enables enforcement of the Git repository allowlist (restricts which
    # external Git providers notebooks can connect to). The actual allowed
    # origins list isn't exposed by this Terraform provider — configure it
    # in Admin Console -> Workspace settings -> Repos once this is applied.
    "enableProjectsAllowList" = "true"
  }
}

# Without this, a workspace admin can set a job's "run as" identity to any
# user or service principal — letting them impersonate someone more
# privileged to run code as them. RESTRICT_TOKENS_AND_JOB_RUN_AS limits
# admins to setting run-as to themselves, or a service principal they
# already have Service Principal User on.
resource "databricks_restrict_workspace_admins_setting" "this" {
  count = var.enable_workspace_hardening ? 1 : 0

  provider = databricks.workspace

  provider_config {
    workspace_id = var.workspace_numeric_id
  }

  restrict_workspace_admins {
    status = "RESTRICT_TOKENS_AND_JOB_RUN_AS"
  }
}
