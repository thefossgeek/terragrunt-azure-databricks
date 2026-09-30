# Deploy the stacks

Do this after [configure](configure.md). The steps are the same for both stacks:

- `02environments/hub`
- `02environments/prod`

## Order: hub first, then prod

`prod` depends on `hub`. Deploy `hub` first and finish it before you start `prod`.

Why: units in `prod` (`06vnet-peering`, `08databricks`, `09unity-catalog`) read the private DNS zones from `hub`'s `03private-dns-zones` unit, at `02environments/hub/.terragrunt-stack/03private-dns-zones`. That folder only exists after `terragrunt stack generate` runs in `hub`, and the zones only exist in Azure after `hub` is applied.

Deploy one stack at a time. Finish all steps for one before you start the other.

## Prerequisites

- [Bootstrap](bootstrap.md) and [configure](configure.md) are done
- `az login` with access to the target subscription
- `terraform` and `terragrunt` (>= 1.1.1) installed
- For `hub`: `export CLOUDFLARE_API_TOKEN=<your token>` (used by the `08cloudflare` unit)

## Step 1: Go to the stack folder

Start with `hub`:

```bash
cd 02environments/hub
```

After `hub` is applied, do the same for `prod`:

```bash
cd 02environments/prod
```

## Step 2: Generate the stack

```bash
terragrunt stack clean && terragrunt stack generate
```

This deletes the old generated files and creates new ones from `terragrunt.stack.hcl`. Run it again every time you change `terragrunt.stack.hcl` or `root.hcl`.

## Step 3: Plan

```bash
terragrunt run --all --fail-fast --summary-per-unit --provider-cache --use-partial-parse-config-cache --non-interactive -- plan -detailed-exitcode
```

Read the plan before you apply. The exit code tells you the result:

| Exit code | Meaning |
|---|---|
| `0` | No changes |
| `1` | Error. Fix it and plan again |
| `2` | Changes to apply |

## Step 4: Apply

```bash
terragrunt run --all --fail-fast --summary-per-unit --provider-cache --use-partial-parse-config-cache -- apply
```

Terragrunt asks for approval before it applies. Type `y` to continue.

## Step 5: Repeat for prod

When `hub` is applied, go back to Step 1 and do `prod`.
