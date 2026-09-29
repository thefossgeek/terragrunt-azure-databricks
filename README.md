# terragrunt-azure-databricks

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue?style=for-the-badge)](LICENSE)
[![Contributing](https://img.shields.io/badge/contributing-welcome-brightgreen?style=for-the-badge)](CONTRIBUTING.md)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-contributor%20covenant-ff69b4?style=for-the-badge)](CODE_OF_CONDUCT.md)
[![Security](https://img.shields.io/badge/security-policy-red?style=for-the-badge)](SECURITY.md)

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.9-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://www.terraform.io)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-%3E%3D1.1.1-5C4EE5?style=flat-square)](https://terragrunt.gruntwork.io)
[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat-square&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com)
[![Databricks](https://img.shields.io/badge/Databricks-FF3621?style=flat-square&logo=databricks&logoColor=white)](https://www.databricks.com)

Infrastructure as Code (IaC) using Terragrunt and Terraform for enterprise Azure Databricks deployments. Implements a secure network boundary with data exfiltration protection (DEP), private endpoints, and strict network controls.

## Getting started

### Step 1: Bootstrap the state backend

Terraform state for this repo is stored in an Azure storage account. If you don't have one, create it first with [01bootstrap](01bootstrap). Follow [docs/bootstrap.md](docs/bootstrap.md).

If you already have a storage account for Terraform state, skip this step.
