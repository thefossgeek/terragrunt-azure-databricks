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

## Getting started

### Step 1: Bootstrap the state backend

Terraform state for this repo is stored in an Azure storage account. If you don't have one, create it first with [01bootstrap](01bootstrap). Follow [docs/bootstrap.md](docs/bootstrap.md).

If you already have a storage account for Terraform state, skip this step.
