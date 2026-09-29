prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/unity-catalog"
}

locals {
  allowed_internet_destinations = yamldecode(file("${dirname(find_in_parent_folders("root.hcl"))}/config/unity-catalog-allowed-internet-destinations.yaml"))
}

inputs = {
  subscription_id          = values.subscription_id
  tenant_id                = values.tenant_id
  location                 = values.location
  location_code            = values.location_code
  environment              = values.environment
  databricks_account_id    = values.databricks_account_id
  databricks_workspace_url = dependency.databricks.outputs.workspace_url
  tags                     = values.tags

  resource_group_name = dependency.resource_groups.outputs.resource_groups["databricks"].name
  subnet_id            = dependency.vnet.outputs.subnets["private-endpoints"].id
  dns_zone_ids = {
    blob = dependency.dns_zones.outputs.zones["storage-blob"].id
    dfs  = dependency.dns_zones.outputs.zones["storage-dfs"].id
  }

  workspace_numeric_id      = dependency.databricks.outputs.workspace_numeric_id
  data_storage_account_id   = dependency.databricks.outputs.storage_account_id
  data_storage_account_name = dependency.databricks.outputs.storage_account_name
  key_vault_id              = dependency.databricks.outputs.key_vault_id

  resource_suffix         = values.resource_suffix
  metastore_name          = values.metastore_name
  storage_container_name  = values.storage_container_name
  data_storage_containers = values.data_storage_containers
  catalog_name           = values.catalog_name
  catalog_isolation_mode = values.catalog_isolation_mode
  is_default_namespace   = values.is_default_namespace
  force_destroy          = values.force_destroy
  storage_account_replication_type = values.storage_account_replication_type

  enable_workspace_hardening         = values.enable_workspace_hardening
  create_network_connectivity_config = values.create_network_connectivity_config
  allowed_internet_destinations       = local.allowed_internet_destinations.destinations

  owner_group_name = dependency.unity_catalog_groups.outputs.group_display_names["catalog_owners"]
}
