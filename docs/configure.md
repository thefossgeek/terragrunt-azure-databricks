# Configure the environments

Do this after [bootstrap](bootstrap.md) and before you deploy anything.

The repo ships template files that end in `.example`. You copy each one without the `.example` suffix, then fill in your values. The copies are git-ignored, so your subscription IDs and user emails never get committed.

## Prerequisites

- [Bootstrap](bootstrap.md) is done (or you already have a state storage account)
- `az login` with access to the target subscription

## Step 1: Rename the files

Run from the repo root:

```bash
for f in $(find 01bootstrap 02environments -name "*.example"); do
  cp "$f" "${f%.example}"
done
```

`cp` keeps the `.example` templates, so you can always compare against them. Use `mv` if you don't want to keep them.

This creates:

| Copy this | To this |
|---|---|
| `01bootstrap/prd/env.hcl.example` | `01bootstrap/prd/env.hcl` (already done if you ran bootstrap) |
| `02environments/hub/root.hcl.example` | `02environments/hub/root.hcl` |
| `02environments/hub/terragrunt.stack.hcl.example` | `02environments/hub/terragrunt.stack.hcl` |
| `02environments/prod/root.hcl.example` | `02environments/prod/root.hcl` |
| `02environments/prod/terragrunt.stack.hcl.example` | `02environments/prod/terragrunt.stack.hcl` |
| `02environments/prod/config/databricks-access.yaml.example` | `02environments/prod/config/databricks-access.yaml` |
| `02environments/prod/config/unity-catalog-groups.yaml.example` | `02environments/prod/config/unity-catalog-groups.yaml` |

## Step 2: Fill in the values

Open each new file and follow the comments in it. Every value that needs your input has a comment above it, including the `az` command to look it up (subscription ID, tenant ID, user emails, and so on).

The comment tags mean:

| Tag | What to do |
|---|---|
| `# REQUIRED` | You must change it |
| `# CHANGE-ME` | Works as-is, change it to match your naming and tags |
| `# SENSITIVE` | Identifies your tenant or people. Keep it out of public repos |

Edit in this order, because later files read from earlier ones:

1. `root.hcl` (in `hub` and `prod`): subscription ID, tenant ID, region, naming, tags
2. `terragrunt.stack.hcl` (in `hub` and `prod`): reads `root.hcl`, then set the values marked `REQUIRED`
3. `prod/config/*.yaml`: group names and member emails

Use the same naming values (`project`, `instance`, and so on) in `hub` and `prod`.

## Step 3: Check your files

Make sure no placeholder is left:

```bash
grep -rn "00000000-0000-0000-0000-000000000000\|contoso.com" 01bootstrap 02environments --include="*.hcl" --include="*.yaml" --exclude="*.example"
```

No output means you're done.

Make sure the copies are git-ignored:

```bash
git status
```

Only the `.example` files should ever show up. If a filled-in file appears, don't commit it.

Next: deploy the stacks.
