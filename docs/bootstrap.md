# Bootstrap the Terraform state backend

Run this once, before anything else in this repo. It creates:

- A resource group, with a delete lock
- A storage account for Terraform state (Entra ID auth only, no shared keys, versioning and soft delete on, delete lock)
- The blob containers listed in `container_names`
- An Entra ID group with `Storage Blob Data Contributor` on the storage account

Module: [modules/bootstrap](../modules/bootstrap)

If you already have a state storage account, skip this and use yours.

## Prerequisites

- `terraform`, `terragrunt` and `az` CLI installed
- `az login` with an account that can create resource groups, storage accounts and Entra ID groups in the target subscription

## Step 1: Create your config

```bash
cd 01bootstrap/prd
cp env.hcl.example env.hcl
```

Open `env.hcl` and change the values. The comment above each value says what to put there:

- `# REQUIRED`: you must change it (subscription ID, storage account name, UPNs)
- `# CHANGE-ME`: works as-is, but change it to match your naming and tags

`env.hcl` is git-ignored. Don't commit it.

## Step 2: Switch to local state

The storage account doesn't exist yet, so the first run has to keep state on your machine.

In `terragrunt.hcl`:

1. Uncomment the `remote_state` block with `backend = "local"`
2. Comment out the `remote_state` block with `backend = "azurerm"`

## Step 3: Apply

```bash
terragrunt init
terragrunt apply
```

State is saved to `01bootstrap/prd/terraform.tfstate`. It's git-ignored. Don't commit it.

## Step 4: Move state into the storage account

1. Back up the local state:

   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

2. In `terragrunt.hcl`, do the reverse of Step 2: comment out the `local` block and uncomment the `azurerm` block.

3. Migrate. Answer **yes** when asked to copy the state:

   ```bash
   terragrunt init -migrate-state
   ```

4. Check that nothing changed:

   ```bash
   terragrunt plan
   ```

   You should see `No changes.` If you don't, stop and fix it before you continue.

5. Delete the local state files:

   ```bash
   rm terraform.tfstate terraform.tfstate.backup
   ```

The backend is ready. The rest of the repo stores its state in this storage account.

## Step 5 (optional): Private endpoint

This closes public access to the storage account. **Do Step 4 first.** If your state is still local after this step, you can't reach it any more.

You need:

- An existing subnet
- An existing `privatelink.blob.core.windows.net` private DNS zone linked to that subnet's VNet
- Network access to that VNet from wherever you run Terraform (VPN, a runner inside the VNet, or similar)

In `env.hcl`:

```hcl
enable_private_endpoint    = true
private_endpoint_subnet_id = "<subnet resource ID>"
private_dns_zone_id        = "<private DNS zone resource ID>"
```

Then run:

```bash
terragrunt apply
```

## Step 6 (optional): Diagnostics

Sends storage read, write and delete logs to an existing Log Analytics workspace.

In `env.hcl`:

```hcl
enable_diagnostics         = true
log_analytics_workspace_id = "<Log Analytics workspace resource ID>"
```

Then run:

```bash
terragrunt apply
```

## Undo Step 5 or 6

Set `enable_private_endpoint` or `enable_diagnostics` back to `false` and run `terragrunt apply`. This removes the private endpoint or the diagnostic setting. The storage account and its data are not changed.

## Add another environment

Copy `01bootstrap/prd/` to a new folder, such as `01bootstrap/dev/`, and do Steps 1–4 there. In the new folder's `terragrunt.hcl`, change `key` in the `azurerm` block to match the new folder. Each environment gets its own subscription, storage account and state. Don't point one environment at another's storage account.

## Outputs

| Output | Value |
|---|---|
| `resource_group_name` | Resource group name |
| `storage_account_name` | Storage account name |
| `storage_account_id` | Storage account resource ID |
| `private_endpoint_id` | Private endpoint resource ID, or `null` if Step 5 wasn't done |
| `group_object_id` | Entra ID group object ID |
