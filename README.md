# terragrunt-azure-databricks
Infrastructure as Code (IaC) using Terragrunt and Terraform for enterprise Azure Databricks deployments. Implements a secure network boundary with data exfiltration protection (DEP), private endpoints, and strict network controls.

## Getting started

### Step 1: Bootstrap the state backend

Terraform state for this repo is stored in an Azure storage account. If you don't have one, create it first with [01bootstrap](01bootstrap). Follow [docs/bootstrap.md](docs/bootstrap.md).

If you already have a storage account for Terraform state, skip this step.
