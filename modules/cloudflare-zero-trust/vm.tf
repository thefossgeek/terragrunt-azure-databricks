# ── Connector VM ──────────────────────────────────────────────────────────────
# One small Linux VM runs cloudflared (the tunnel) and a local DNS forwarder.
# No SSH access is required for normal operation — everything is provisioned
# via cloud-init — but a key pair is still generated since Azure requires one
# for a Linux VM with password auth disabled.

resource "tls_private_key" "connector" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "connector" {
  name                = "nic-${var.resource_suffix}-connector"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "connector" {
  name                            = "vm-${var.resource_suffix}-connector"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.connector.id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.connector.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Managed boot diagnostics (no storage account to create/manage) — lets you
  # pull the boot/serial log via `az vm boot-diagnostics get-boot-log` when
  # troubleshooting cloud-init.
  boot_diagnostics {
    storage_account_uri = null
  }

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }

  # Registers this VM against the tunnel created in tunnel.tf, in the same
  # apply — no cross-stack dependency/mock-output dance needed since both live
  # in one module.
  custom_data = base64encode(templatefile("${path.module}/scripts/cloud-init.sh.tftpl", {
    tunnel_id            = cloudflare_zero_trust_tunnel_cloudflared.this.id
    tunnel_secret        = random_id.tunnel_secret.b64_std
    account_id           = var.cloudflare_account_id
    connector_private_ip = azurerm_network_interface.connector.private_ip_address
  }))

  # cloud-init needs working outbound internet on its first (and only) boot to
  # apt-get install/download cloudflared. The subnet's NAT Gateway association
  # is a separate resource with no attribute-level link to the VM, so without
  # this explicit dependency Terraform can boot the VM before outbound internet
  # is actually wired up — cloud-init then fails partway and never retries.
  # The subnet's NSG association is managed upstream (02environments/hub's
  # 04nsg unit) and applies before this unit runs via the stack's own
  # dependency graph, so no depends_on is needed for it here.
  depends_on = [
    azurerm_subnet_nat_gateway_association.connector,
  ]
}
