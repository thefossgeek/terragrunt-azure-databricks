output "id" {
  description = "Resource ID of the Private DNS Resolver."
  value       = azurerm_private_dns_resolver.this.id
}

output "inbound_endpoint_id" {
  description = "Resource ID of the inbound endpoint."
  value       = azurerm_private_dns_resolver_inbound_endpoint.this.id
}

output "inbound_endpoint_ip" {
  description = "Private IP spokes should set as a custom DNS server on their VNet to resolve zones linked to this hub VNet."
  value       = azurerm_private_dns_resolver_inbound_endpoint.this.ip_configurations[0].private_ip_address
}
