<h1 align="center">terragrunt-azure-databricks</h1>

<p align="center">
  Infrastructure as Code (IaC) using Terragrunt and Terraform for enterprise Azure Databricks deployments.<br>
  Implements a secure network boundary with data exfiltration protection (DEP), private endpoints, and strict network controls.
</p>

<p align="center">
  <a href="https://www.terraform.io"><img alt="Terraform" src="https://img.shields.io/badge/Terraform-%3E%3D1.9-7B42BC?style=for-the-badge&logo=terraform&logoColor=white"></a>
  <a href="https://terragrunt.gruntwork.io"><img alt="Terragrunt" src="https://img.shields.io/badge/Terragrunt-%3E%3D1.1.1-5C4EE5?style=for-the-badge"></a>
  <a href="https://azure.microsoft.com"><img alt="Azure" src="https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white"></a>
  <a href="https://www.databricks.com"><img alt="Databricks" src="https://img.shields.io/badge/Databricks-FF3621?style=for-the-badge&logo=databricks&logoColor=white"></a>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge"></a>
  <a href="CONTRIBUTING.md"><img alt="Contributing" src="https://img.shields.io/badge/Contributing-welcome-brightgreen?style=for-the-badge"></a>
  <a href="CODE_OF_CONDUCT.md"><img alt="Code of Conduct" src="https://img.shields.io/badge/Code%20of%20Conduct-v2.1-ff69b4?style=for-the-badge"></a>
  <a href="SECURITY.md"><img alt="Security" src="https://img.shields.io/badge/Security-policy-red?style=for-the-badge"></a>
</p>

## Prerequisites

Complete this checklist before you start. Details and commands are in [docs/prerequisites.md](docs/prerequisites.md).

| Area | What you need |
|---|---|
| Tools | `terraform` >= 1.9, `terragrunt` >= 1.1.1, `az` CLI |
| Azure subscription | One subscription (hub and prod together) or two. Resource providers registered. |
| Azure RBAC | `Owner`, or `Contributor` + `User Access Administrator`, on the subscription |
| Microsoft Entra ID | `Groups Administrator`, `Application Administrator`, and `Privileged Role Administrator` or `Global Administrator` |
| MFA | Security defaults or a Conditional Access policy enabled in Entra ID |
| Databricks | Account admin access and your Databricks account ID |
| Cloudflare | Zero Trust account, team name, account ID and an API token |

## Deploy the platform in 4 steps

| Step | What it does | Guide |
|---|---|---|
| [1. Bootstrap](#step-1-bootstrap-the-state-backend) | Creates the storage account that holds Terraform state | [docs/bootstrap.md](docs/bootstrap.md) |
| [2. Configure](#step-2-configure-the-environments) | Creates your config files from the `.example` templates | [docs/configure.md](docs/configure.md) |
| [3. Deploy](#step-3-deploy-the-stacks) | Generates, plans and applies the `hub` and `prod` stacks | [docs/deploy.md](docs/deploy.md) |
| [4. Sign in](#step-4-sign-in) | Connects users to the account console, workspace and Azure portal | below |

### Step 1: Bootstrap the state backend

Creates the Azure storage account that holds Terraform state for this repo.

- **Do this if** you don't have a state storage account yet.
- **Skip this if** you already have one.
- **Guide:** [docs/bootstrap.md](docs/bootstrap.md)

### Step 2: Configure the environments

Copy each `.example` file to the same name without `.example`, then follow the comments in each file to set your values (subscription ID, tenant ID, user emails, and so on).

- **Guide:** [docs/configure.md](docs/configure.md)

### Step 3: Deploy the stacks

Generate, plan and apply each stack. Deploy `hub` first, then `prod`, because `prod` depends on `hub`.

- **Guide:** [docs/deploy.md](docs/deploy.md)

### Step 4: Sign in

There are three ways in. Only the workspace goes through Cloudflare.

![Connectivity: how users reach Azure Databricks](docs/images/connectivity.svg)

| # | What | How you connect |
|---|---|---|
| 1 | Databricks account console | Over the internet. Open [accounts.azuredatabricks.net](https://accounts.azuredatabricks.net) and sign in with Entra ID and complete MFA. |
| 2 | Databricks workspace | Through Cloudflare only. The workspace has no public access. See below. |
| 3 | Azure portal | Over the internet. Open [portal.azure.com](https://portal.azure.com) and sign in with Entra ID and complete MFA. |

#### Sign in to the workspace

1. Ask an admin to add you to the Entra ID group `zero-trust-private-access` (`access_group_name` in `hub`'s `terragrunt.stack.hcl`).
2. Install the [Cloudflare WARP client](https://one.one.one.one).
3. In WARP, go to Preferences > Account > Login to Cloudflare Zero Trust, enter your team name, and sign in with Entra ID and complete MFA.
4. Get the workspace URL:

   ```bash
   az databricks workspace list --query "[].workspaceUrl" -o tsv
   ```

5. With WARP connected, open `https://<workspaceUrl>` in your browser.

If the page doesn't load, check that WARP shows **Connected** and that you're in the group from step 1.
