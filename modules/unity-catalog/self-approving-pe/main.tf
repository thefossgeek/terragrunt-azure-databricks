locals {
  # Find the pending PE connection created by the NCC rule by matching its endpoint name.
  # Derive the connection name from its `id` rather than reading a `name` attribute
  # directly — some resource types (e.g. Key Vault) don't include `name` on each
  # entry in privateEndpointConnections, only `id` and `properties`.
  pe_name = [
    for pe in data.azapi_resource.this.output.properties.privateEndpointConnections :
    element(split("/", pe.id), length(split("/", pe.id)) - 1)
    if endswith(pe.properties.privateEndpoint.id, databricks_mws_ncc_private_endpoint_rule.this.endpoint_name)
  ][0]

  ncc_description_id = var.network_connectivity_config_name == "" ? (
    "NCC ID: ${var.network_connectivity_config_id}"
  ) : "NCC Name: ${var.network_connectivity_config_name}"

  update_body = {
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved for Databricks ${local.ncc_description_id}"
        status      = "Approved"
      }
    }
  }
}

# Ask Databricks to create a managed private endpoint from its serverless VNet
# to the target Azure resource (e.g. a storage account).
# account_id is NOT set here — as of databricks provider 1.121.0 it's a
# computed-only attribute (inferred from the account-level provider config),
# no longer a configurable argument. Was required in earlier provider
# versions; var.databricks_account_id is kept for callers/backward compat
# but is unused internally now.
resource "databricks_mws_ncc_private_endpoint_rule" "this" {
  network_connectivity_config_id = var.network_connectivity_config_id
  resource_id                    = var.resource_id
  group_id                       = var.group_id
}

# Read back the storage account (or other resource) to discover the name of the
# pending private endpoint connection that Databricks just created above.
data "azapi_resource" "this" {
  type                   = var.data_api_type
  resource_id            = var.resource_id
  response_export_values = ["properties.privateEndpointConnections"]

  depends_on = [databricks_mws_ncc_private_endpoint_rule.this]
}

# Approve the pending connection. Without this, the PE exists but traffic is
# blocked because the storage account requires manual approval.
resource "azapi_update_resource" "this" {
  type      = var.update_api_type
  name      = local.pe_name
  parent_id = var.resource_id
  body      = local.update_body
}
