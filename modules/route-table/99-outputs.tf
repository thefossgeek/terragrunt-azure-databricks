output "route_tables" {
  description = "Created route tables, keyed by purpose."
  value = {
    for key, rt in azurerm_route_table.this : key => {
      id   = rt.id
      name = rt.name
    }
  }
}
