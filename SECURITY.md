# Security Policy

## Reporting a vulnerability

Please don't open a public issue for security problems.

Report it privately through GitHub instead: go to the **Security** tab of this repository and click **Report a vulnerability**.

Include what you found, where it is (file and line), and how to reproduce it. You'll get a reply as soon as possible.

## Sensitive data

This repository must never contain real subscription IDs, tenant IDs, credentials, or user details. Real config files (`env.hcl`, `root.hcl`, `terragrunt.stack.hcl`, and the user lists in `config/`) are git-ignored; only `.example` copies with placeholder values are committed.

If you spot a real value that was committed by mistake, report it as above.
