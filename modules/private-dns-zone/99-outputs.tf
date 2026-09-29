output "zones" {
  description = "Zones used by this stack, keyed by purpose — either created here (create_zone = true) or looked up (create_zone = false)."
  value = {
    for key, zone in var.zones : key => {
      id   = try(azurerm_private_dns_zone.this[key].id, data.azurerm_private_dns_zone.this[key].id)
      name = zone.name
    }
  }
}
