prevent_destroy = false

include "common" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_repo_root()}/modules/databricks"
}

locals {
  access = yamldecode(file("${dirname(find_in_parent_folders("root.hcl"))}/config/databricks-access.yaml"))
}

inputs = {
  subscription_id       = values.subscription_id
  tenant_id             = values.tenant_id
  databricks_account_id = values.databricks_account_id
  location              = values.location
  location_code         = values.location_code
  environment           = values.environment
  tags                  = values.tags

  name                              = values.name
  managed_resource_group_name       = values.managed_resource_group_name
  access_connector_name             = values.access_connector_name
  storage_account_name              = values.storage_account_name
  managed_dbfs_storage_account_name = values.managed_dbfs_storage_account_name
  key_vault_name                    = values.key_vault_name

  resource_group_name = dependency.resource_groups.outputs.resource_groups["databricks"].name

  virtual_network_id                           = dependency.vnet.outputs.vnet_id
  databricks_public_subnet_name                = dependency.vnet.outputs.subnets["databricks-public"].name
  databricks_private_subnet_name               = dependency.vnet.outputs.subnets["databricks-private"].name
  databricks_public_subnet_nsg_association_id  = dependency.nsg.outputs.subnet_associations["databricks-public"]
  databricks_private_subnet_nsg_association_id = dependency.nsg.outputs.subnet_associations["databricks-private"]
  private_endpoint_subnet_id                   = dependency.vnet.outputs.subnets["private-endpoints"].id

  dns_zone_id_databricks   = dependency.dns_zones.outputs.zones["databricks"].id
  dns_zone_id_storage_blob = dependency.dns_zones.outputs.zones["storage-blob"].id
  dns_zone_id_storage_dfs  = dependency.dns_zones.outputs.zones["storage-dfs"].id
  dns_zone_id_key_vault    = dependency.dns_zones.outputs.zones["key-vault"].id

  log_analytics_workspace_id = dependency.log_analytics.outputs.id
  alert_email                = values.alert_email

  sku                              = values.sku
  managed_dbfs_storage_sku_name    = values.managed_dbfs_storage_sku_name
  enable_dbfs_storage_firewall     = values.enable_dbfs_storage_firewall
  storage_account_replication_type = values.storage_account_replication_type
  storage_containers               = values.storage_containers

  compliance_security_profile_enabled   = values.compliance_security_profile_enabled
  compliance_security_profile_standards = values.compliance_security_profile_standards
  enhanced_security_monitoring_enabled  = values.enhanced_security_monitoring_enabled
  automatic_cluster_update_enabled      = values.automatic_cluster_update_enabled

  key_vault_tf_contrib_group_id = values.tf_contrib_group_id

  reader_group_name         = values.reader_group_name
  reader_group_members      = local.access.reader
  contributor_group_name    = values.contributor_group_name
  contributor_group_members = local.access.contributor

  reader_roles = {
    key_vault = "Key Vault Secrets User"
    workspace = "Reader"
  }

  contributor_roles = {
    key_vault = "Key Vault Secrets Officer"
    workspace = "Contributor"
  }
}
