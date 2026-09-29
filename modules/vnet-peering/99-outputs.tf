output "source_to_destination_peering_id" {
  description = "Source-to-destination peering resource ID."
  value       = azurerm_virtual_network_peering.source_to_destination.id
}

output "destination_to_source_peering_id" {
  description = "Destination-to-source peering resource ID."
  value       = azurerm_virtual_network_peering.destination_to_source.id
}

output "source_to_destination_peering_name" {
  description = "Source-to-destination peering name."
  value       = azurerm_virtual_network_peering.source_to_destination.name
}

output "destination_to_source_peering_name" {
  description = "Destination-to-source peering name."
  value       = azurerm_virtual_network_peering.destination_to_source.name
}
