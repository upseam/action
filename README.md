<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/upseam-banner-dark.svg" />
    <img src=".github/assets/upseam-banner-light.svg" width="880" alt="Upseam. Dependabot for your APIs." />
  </picture>
</p>

# Upseam Action

[**Try for free ↗**](https://app.upseam.dev) · [Docs](https://docs.upseam.dev/) · [Demo](https://github.com/upseam/demo) · [Vote for the next API](https://app.upseam.dev/vote) ·
[Privacy](https://docs.upseam.dev/privacy/) · [Security](https://docs.upseam.dev/security/)

- Finds the external API changes that affect your repository and writes a report to the run page.
- Covers Stripe, Shopify (Admin and Storefront APIs) and the models of OpenAI, Anthropic and Gemini, in JavaScript, TypeScript and Python: [Providers](https://docs.upseam.dev/providers/).
- The free report needs only `contents: read`. No App, account, model or token.

## Free report on the run page

```yaml
name: upseam
on:
  schedule:
    - cron: "17 6 * * 1"
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upseam:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          persist-credentials: false
      - uses: upseam/action@v0
```

- **Deadlines** first: the date with a countdown, the API and what changes.
- **Changes to make:** each finding as `file:line`, linked to the line in the scanned commit, with the successor the change data names.
- **Needs you:** the behavior changes. Upseam does not patch them.
- A **coverage line** says what was and was not checked, also when nothing is found.
- GitHub shows at most 1 MiB per step; a longer summary is cut at a whole finding and says how many were left out.

## Issue and `fix`

- `issue: true` keeps one issue, **Upseam watches this repository**: created when missing, edited only when the findings change, updated but never reopened when closed. Text from your repository is escaped, so it pings no one. Add `concurrency: upseam` to the job.
- `fix: true` opens one pull request per run for a mechanical breaking change. A retired model id with exactly one replacement named by the vendor is replaced directly, with no model and no key; any other mechanical change and the matched files go to your model. Behavior changes are never patched; every patch passes the same gates as the Upseam App first.
- For changes your model writes, `fix` needs your own model key as a repository secret, `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`, passed with `model-key`; without it they are skipped. A key in the step `env` reaches every step of the Action.
- With `fix`, pin the Action to a full commit SHA (`upseam/action@<40-character commit SHA> # v0.x`): the step holds your key and pushes. `verify` is refused; run your tests in your pull request workflow with `contents: read`.
- **Permissions:** the free report needs `contents: read`; `issue: true` adds `issues: write`; `fix: true` needs `contents: write` and `pull-requests: write`, plus `issues: write` only with `issue: true`.

## Inputs

| Input         | Default                  | What it does                                                                                    |
| ------------- | ------------------------ | ----------------------------------------------------------------------------------------------- |
| `path`        | `.`                      | Directory to scan, relative to the workspace.                                                   |
| `issue`       | `false`                  | `true` also keeps one issue up to date. Needs `issues: write` on the token.                     |
| `token`       | `github.token`           | Used only with `issue` or `fix`. The run summary needs no token.                                |
| `fix`         | `false`                  | `true` opens one pull request per run for a breaking mechanical change.                         |
| `vendor`      | empty (`anthropic`)      | Model vendor for `fix`: `anthropic` or `openai`.                                                |
| `model`       | empty                    | Model id as the vendor names it. Default `claude-opus-5-5` for `anthropic`; required for `openai`. |
| `base-url`    | empty                    | API base URL for an OpenAI-compatible vendor.                                                   |
| `verify`      | empty                    | Refused. With `fix`, a non-empty value fails the run before anything is generated.              |
| `model-key`   | empty                    | Model key for `fix`, passed only to the generate step; not needed for a direct model swap.      |
| `group`       | set by the App's event   | For the Upseam App: the group of an `upseam-generate` or `upseam-agent` dispatch event.         |
| `agent-edits` | set by the App's event   | For the Upseam App: take the patch from your own coding agent's edits instead of a model.       |
| `check-only`  | `false`                  | For the Upseam App: check the patch with the Upseam gates without pushing.                      |

## What leaves the runner

- **Free report:** nothing. The detector runs on the runner with the change data bundled in the Action; no token is passed to the step. Only `actions/setup-node` may download Node.js 22.
- **`issue: true`:** GitHub API calls to your own repository with `token`, to read, create and edit the issue.
- **`fix: true`:** GitHub API calls with `token` to look up pull requests, push one branch and open one, and, except for a direct model replacement, calls to your model vendor with your key. They carry the change and the matched files, with likely secrets replaced first: [Secrets in your files](https://docs.upseam.dev/security/#secrets-in-your-files). The key goes only to that vendor and is never printed or written.
- The Action sends nothing to Upseam servers.

## More

- `group`, `agent-edits` and `check-only` serve the Upseam GitHub App: on its `repository_dispatch` event the Action writes the patch with your model or coding agent and pushes `upseam/<group>`.
- The reusable workflow `.github/workflows/agent.yml` runs your agent: [Bring your own agent](https://docs.upseam.dev/own-agent/).
- No App at all: [Run Upseam without the App](https://docs.upseam.dev/without-the-app/).
- Report a vulnerability privately to <contact@upseam.dev>, not in a public issue.
