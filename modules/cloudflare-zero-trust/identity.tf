# ── Entra ID App Registration for Cloudflare Access SSO ─────────────────────
# Cloudflare Access uses this as its OIDC identity provider so WARP/Access
# logins go through Entra ID. Fully created here — no manual App Registration
# needed.

data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

locals {
  msgraph_app_roles     = { for role in data.azuread_service_principal.msgraph.app_roles : role.value => role.id }
  msgraph_oauth2_scopes = { for scope in data.azuread_service_principal.msgraph.oauth2_permission_scopes : scope.value => scope.id }
}

resource "azuread_application" "cloudflare_access" {
  display_name = "cloudflare-access-${var.resource_suffix}"

  web {
    redirect_uris = ["https://${var.cloudflare_team_name}.cloudflareaccess.com/cdn-cgi/access/callback"]
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

    resource_access {
      id   = local.msgraph_oauth2_scopes["openid"]
      type = "Scope"
    }
    resource_access {
      id   = local.msgraph_oauth2_scopes["profile"]
      type = "Scope"
    }
    resource_access {
      id   = local.msgraph_oauth2_scopes["email"]
      type = "Scope"
    }
    resource_access {
      id   = local.msgraph_oauth2_scopes["offline_access"]
      type = "Scope"
    }
    resource_access {
      id   = local.msgraph_oauth2_scopes["User.Read"]
      type = "Scope"
    }
    # Application permission (not delegated) — lets Cloudflare read the signed-in
    # user's group memberships via Graph, which is what support_groups below
    # needs. Requires admin consent (see the role assignment further down).
    resource_access {
      id   = local.msgraph_app_roles["Directory.Read.All"]
      type = "Role"
    }
  }
}

resource "azuread_service_principal" "cloudflare_access" {
  client_id = azuread_application.cloudflare_access.client_id
}

resource "azuread_application_password" "cloudflare_access" {
  # .id (not .object_id) — this provider version returns a Graph-style
  # "/applications/{object_id}" path here, which is what this argument expects.
  application_id = azuread_application.cloudflare_access.id
}

# Grants admin consent for the Directory.Read.All application permission
# above. Requires the identity running Terraform to hold Application
# Administrator / Privileged Role Administrator / Global Administrator in
# Entra ID. If it doesn't, this resource will fail — grant consent once
# manually instead via Entra ID → Enterprise Applications →
# cloudflare-access-${resource_suffix} → Permissions → Grant admin consent.
resource "azuread_app_role_assignment" "cloudflare_access_directory_read" {
  app_role_id         = local.msgraph_app_roles["Directory.Read.All"]
  principal_object_id = azuread_service_principal.cloudflare_access.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "cloudflare_zero_trust_access_identity_provider" "entra_id" {
  account_id = var.cloudflare_account_id
  name       = "entra-id-${var.resource_suffix}"
  type       = "azureAD"

  config = {
    client_id                  = azuread_application.cloudflare_access.client_id
    client_secret              = azuread_application_password.cloudflare_access.value
    directory_id               = var.tenant_id
    support_groups             = true
    pkce_enabled               = true
    conditional_access_enabled = false
  }
}
