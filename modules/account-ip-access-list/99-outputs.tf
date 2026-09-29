output "network_policy_id" {
  description = "ID of the account network policy managed by this module."
  value       = databricks_account_network_policy.this.network_policy_id
}

output "account_id" {
  description = "Databricks account ID this policy belongs to."
  value       = databricks_account_network_policy.this.account_id
}

output "restriction_mode" {
  description = "Effective public-access restriction mode (\"FULL_ACCESS\" or \"RESTRICTED_ACCESS\") - useful to confirm the Enabled/disabled toggle applied as expected."
  value       = databricks_account_network_policy.this.ingress.public_access.restriction_mode
}
