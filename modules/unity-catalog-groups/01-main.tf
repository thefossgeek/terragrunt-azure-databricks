locals {
  # Only groups with at least one member actually get created.
  groups_to_create = { for key, g in var.groups : key => g if length(g.members) > 0 }

  # Every UPN across every group, deduplicated — one lookup per person even
  # if they're in multiple groups.
  all_members = toset(flatten([for g in local.groups_to_create : g.members]))
}

data "azuread_user" "this" {
  for_each            = local.all_members
  user_principal_name = each.value
}

resource "azuread_group" "this" {
  for_each = local.groups_to_create

  display_name     = each.value.display_name
  security_enabled = true
  members          = [for m in each.value.members : data.azuread_user.this[m].object_id]
}
