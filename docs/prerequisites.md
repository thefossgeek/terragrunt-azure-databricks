# Prerequisites

Complete every section below before you start [bootstrap](bootstrap.md).

**Contents:** [Tools](#tools) · [Azure subscription](#azure-subscription) · [Azure RBAC role](#azure-rbac-role-who-runs-terraform) · [Entra ID roles](#microsoft-entra-id-roles-who-runs-terraform) · [Databricks](#databricks) · [Cloudflare](#cloudflare) · [MFA](#multi-factor-authentication-mfa) · [Other](#other) · [Verify](#verify-your-setup)

## Tools

- `terraform` >= 1.9
- `terragrunt` >= 1.1.1
- `az` CLI, signed in with `az login`

## Azure subscription

- **One subscription** works for both `hub` and `prod`. This is what the examples assume, because this repo was built and tested on a single free-tier subscription. Set `subscription_id` and `hub_subscription_id` to the same value.
- **Two subscriptions** is better for production: put `hub` in a connectivity subscription and `prod` in its own. Set `hub_subscription_id` in `prod`'s `root.hcl` to the hub's ID.
- Register these resource providers in each subscription:

  ```bash
  for p in Microsoft.Databricks Microsoft.Network Microsoft.Storage Microsoft.KeyVault \
           Microsoft.OperationalInsights Microsoft.Compute Microsoft.Insights; do
    az provider register --namespace $p
  done
  ```

- Enough quota in your region for a small Linux VM (the Cloudflare connector). If the VM size isn't available, change `vm_size` in the `cloudflare-zero-trust` module.

## Azure RBAC role (who runs Terraform)

- `Owner` on the subscription, or `Contributor` plus `User Access Administrator`. The code creates role assignments, so `Contributor` alone fails.

## Microsoft Entra ID roles (who runs Terraform)

- `Groups Administrator`: creates the Entra ID groups and manages their members
- `Application Administrator`: creates the Cloudflare Access app registration
- `Privileged Role Administrator` or `Global Administrator`: grants admin consent for `Directory.Read.All` on that app registration

## Databricks

- An Azure Databricks **account** with you as **account admin**. Sign in at [accounts.azuredatabricks.net](https://accounts.azuredatabricks.net).
- Your **Databricks account ID** (account console, click your user name, top right). It goes in `prod`'s `root.hcl`.

## Cloudflare

- A Cloudflare account with **Zero Trust** enabled (the free plan works) and a **team name** set (Zero Trust > Settings > Team name).
- Your Cloudflare **account ID** (Account home > Account ID).
- A Cloudflare **API token** with these Account permissions:
  - `Zero Trust`: Edit
  - `Access: Apps and Policies`: Edit
  - `Access: Organizations, Identity Providers, and Groups`: Edit
  - `Cloudflare Tunnel`: Edit

  Export it before you deploy `hub`:

  ```bash
  export CLOUDFLARE_API_TOKEN=<your token>
  ```

- Users who will connect need the Cloudflare **WARP** client installed.

## Multi-factor authentication (MFA)

All three ways in sign in with Entra ID, so MFA is enforced by Entra ID, not by this repo. Turn it on before you deploy. Pick one:

- **Security defaults** (free, no licence): Entra admin center > Identity > Overview > Properties > Manage security defaults > **Enabled**. This requires MFA for every user in the tenant.
- **Conditional Access** (needs Entra ID P1): create a policy that grants access only with **Require multifactor authentication** for these apps:

  | Access | App in the policy |
  |---|---|
  | Azure portal | `Microsoft Azure Management` |
  | Databricks account console and workspace | `AzureDatabricks` |
  | Workspace through Cloudflare | `cloudflare-access-<resource_suffix>` (created by the `hub` deploy, so add it after `hub` is applied) |

Don't use both. Security defaults turns off when you use Conditional Access.

## Other

- An Entra ID user (UPN) for each person who goes in a reader, contributor or Unity Catalog group.

## Verify your setup

Run these. Each one should succeed.

```bash
terraform -version                 # 1.9 or later
terragrunt --version               # 1.1.1 or later
az account show -o table           # the subscription you plan to deploy into
az provider show -n Microsoft.Databricks --query registrationState -o tsv   # Registered
echo ${CLOUDFLARE_API_TOKEN:+set}  # prints "set" if the token is exported
```

Then go to [bootstrap](bootstrap.md).
