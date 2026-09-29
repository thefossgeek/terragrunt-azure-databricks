locals {
  tags = merge(
    { managed_by = "terraform" },
    var.tags
  )
}

resource "azurerm_resource_group" "this" {
  for_each = var.resource_groups

  name     = each.value.name
  location = var.location
  tags     = merge(local.tags, { layer = each.key })
}

# ── Locking — one flag, applies to every resource group ─────────────────────
# CanNotDelete blocks delete only; ReadOnly also blocks any write/update.
# Toggle var.enable_lock in the terragrunt inputs — nothing else to touch.

resource "azurerm_management_lock" "this" {
  for_each = var.enable_lock ? var.resource_groups : {}

  name       = "lock-${each.value.name}"
  scope      = azurerm_resource_group.this[each.key].id
  lock_level = var.lock_level
}
