variable "resource_group_name" {
  description = "Resource group to create the zones in — the spoke's network RG, or the hub's RG when centralizing there."
  type        = string
}

variable "zones" {
  description = "Private DNS zones keyed by purpose (e.g. storage-blob, key-vault, adf-data-factory)."
  type = map(object({
    name                 = string # actual DNS zone name, e.g. "privatelink.blob.core.windows.net" — fixed by Azure, not derived
    vnet_id              = string # can be in a different subscription than this zone — no extra provider needed
    registration_enabled = optional(bool, false)
    # false when another stack already created this zone (e.g. centralized
    # in the hub) — this stack then only looks it up and adds its own VNet
    # link, same create_dns_zone gate pattern as modules/databricks-app.
    create_zone = optional(bool, true)
  }))
  default = {}
}
