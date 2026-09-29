.PHONY: fmt fmt-check

# Format all Terraform (.tf) and Terragrunt (.hcl) files
fmt:
	terraform fmt -recursive
	terragrunt hcl fmt

# Check formatting without changing files (fails if anything needs formatting)
fmt-check:
	terraform fmt -recursive -check
	terragrunt hcl fmt --check
