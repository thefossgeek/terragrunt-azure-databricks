output "connector_private_ip" {
  description = "Private IP of the connector VM — also the DNS server address used in fallback_domains."
  value       = azurerm_network_interface.connector.private_ip_address
}

output "cloudflare_tunnel_id" {
  description = "ID of the Cloudflare Tunnel."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "cloudflare_access_group_id" {
  description = "Object ID of the Entra ID group gating Zero Trust access."
  value       = azuread_group.zero_trust_access.object_id
}

output "entra_app_client_id" {
  description = "Client (application) ID of the Entra ID app registration used as Cloudflare Access's IdP."
  value       = azuread_application.cloudflare_access.client_id
}

output "device_profile_policy_id" {
  description = "Policy ID of the WARP device profile — needed for direct API calls against /devices/policy/{id}, e.g. to inspect fallback_domains or include routes."
  value       = cloudflare_zero_trust_device_custom_profile.this.policy_id
}

output "connector_vm_ssh_private_key" {
  description = "SSH private key for the connector VM, for troubleshooting only — the VM is provisioned entirely via cloud-init."
  value       = tls_private_key.connector.private_key_openssh
  sensitive   = true
}
