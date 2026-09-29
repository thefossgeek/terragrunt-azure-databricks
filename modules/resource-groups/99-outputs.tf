output "resource_groups" {
  description = "Created resource groups, keyed by layer."
  value = {
    for key, rg in azurerm_resource_group.this : key => {
      name = rg.name
      id   = rg.id
    }
  }
}
