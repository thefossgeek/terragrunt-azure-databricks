# Contributing

Thanks for helping improve this project. Bug reports, fixes and new modules are all welcome.

## Before you start

- **Bug or idea?** Open an [issue](../../issues/new/choose) first, so we can agree on the approach before you write code.
- **Security problem?** Don't open a public issue. See [SECURITY.md](SECURITY.md).

## Making a change

1. Fork the repo and create a branch from `main`.
2. Make your change. Keep each pull request to one topic.
3. Format your code:

   ```bash
   terraform fmt -recursive
   terragrunt hcl fmt
   ```

4. Test it: run `terragrunt plan` for the stack or unit you changed and check the output.
5. Open a pull request and fill in the template.

## The one hard rule: no real values

Never commit real subscription IDs, tenant IDs, object IDs, account IDs, emails or other values from your own environment.

- Real config lives in git-ignored files: `env.hcl`, `root.hcl`, `terragrunt.stack.hcl`, `config/databricks-access.yaml` and `config/unity-catalog-groups.yaml`.
- If you add a setting to one of those files, add it to the matching `.example` file too, with a placeholder value and a short comment saying what to put there.

Pull requests that contain real values will be closed, and the values should be treated as exposed.

## Pull request review

All changes to `main` go through a pull request and need approval from the maintainer. PRs are merged with squash or rebase, so keep your branch up to date with `main`.

By contributing, you agree that your work is licensed under this repo's [LICENSE](LICENSE) and that you follow the [Code of Conduct](CODE_OF_CONDUCT.md).
