output "network_security_groups" {
  description = "Created NSGs, keyed by purpose."
  value = {
    for key, nsg in azurerm_network_security_group.this : key => {
      id   = nsg.id
      name = nsg.name
    }
  }
}

output "subnet_associations" {
  description = "Subnet<->NSG association resource IDs, keyed by purpose (only entries that set subnet_id)."
  value = {
    for key, assoc in azurerm_subnet_network_security_group_association.this : key => assoc.id
  }
}
