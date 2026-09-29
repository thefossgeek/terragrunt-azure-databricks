# Account console IP access list. Modeled as one databricks_account_network_policy
# resource (network_policy_id = "default-policy") rather than a dedicated IP
# access list resource - the account-level Network Policies API is what now
# backs that UI page, and account_ui is only a valid destination on the
# account-level policy. See databricks_account_network_policy provider docs.

resource "databricks_account_network_policy" "this" {
  provider = databricks.account

  network_policy_id = var.network_policy_id

  # This module only manages ingress (who can reach the account console UI).
  # The API requires egress.network_access.restriction_mode regardless - it
  # shares the same two-value enum as ingress (confirmed by the provider's
  # own validation panic: "OPEN_ACCESS" is not a valid value here, despite
  # being documented terminology elsewhere for the unrestricted state).
  # FULL_ACCESS leaves outbound network access completely unrestricted, i.e.
  # explicitly "not managing this" rather than actually restricting anything.
  egress = {
    network_access = {
      restriction_mode = "FULL_ACCESS"
    }
  }

  ingress = {
    public_access = {
      restriction_mode = var.enabled ? "RESTRICTED_ACCESS" : "FULL_ACCESS"

      allow_rules = [
        for rule in var.allow_rules : {
          label = rule.label
          destination = {
            account_ui = {
              all_destinations = true
            }
          }
          origin = {
            included_ip_ranges = {
              ip_ranges = rule.ip_addresses
            }
          }
        }
      ]

      deny_rules = [
        for rule in var.block_rules : {
          label = rule.label
          destination = {
            account_ui = {
              all_destinations = true
            }
          }
          origin = {
            included_ip_ranges = {
              ip_ranges = rule.ip_addresses
            }
          }
        }
      ]
    }
  }
}
