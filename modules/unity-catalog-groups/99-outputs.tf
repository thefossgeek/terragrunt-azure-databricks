output "group_display_names" {
  description = "Group key -> display name (null if skipped)."
  value       = { for key, g in var.groups : key => try(azuread_group.this[key].display_name, null) }
}

output "group_object_ids" {
  description = "Group key -> object ID (null if skipped)."
  value       = { for key, g in var.groups : key => try(azuread_group.this[key].object_id, null) }
}
