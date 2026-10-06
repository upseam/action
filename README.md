# Upseam Action

Finds the external API changes that affect your repository and writes a report
to the run page: the deadlines first, then each finding as a link to the line in
the scanned commit with the named successor, then the behavior changes that need
you. It covers Stripe, Shopify, and the models of OpenAI, Anthropic and Gemini.

The free report needs the `contents: read` right. No App, no account, no model
and no token.

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

Every run appends a Markdown summary to the run page:

- **API changes affecting this repository** is the heading.
- **Deadlines** come first: the date with a countdown, the API, and what changes.
- **Changes to make** lists each finding as `file:line`, linked to the line in
  the scanned commit, with the successor the change data names.
- **Needs you** lists the behavior changes. Upseam does not patch them.
- A **coverage line** says what was checked and what was not. When nothing is
  found, the summary says so, with that line.

GitHub shows at most 1 MiB per step, so a longer summary is cut at a whole
finding and says how many were left out.

## Keep one issue

```yaml
permissions:
  contents: read
  issues: write
concurrency: upseam
# …
      - uses: upseam/action@v0
        with:
          issue: true
```

The issue **Upseam watches this repository** is created when missing and edited
only when the findings change. A closed issue is updated but never reopened.
Text from your repository is escaped, so the issue pings no one.

## Patch pull requests with `fix`

For a breaking change that is mechanical, `fix` sends the change and the matched
files to your model and opens one pull request per run with the result. Behavior
changes are never patched. The reply must pass the same gates as the Upseam App
before anything is written.

```yaml
permissions:
  contents: write
  issues: write
  pull-requests: write
# …
      - uses: upseam/action@<40-character commit SHA> # v0.x
        with:
          issue: true
          fix: true
          model-key: ${{ secrets.ANTHROPIC_API_KEY }}
```

- `fix` needs your own model key as a repository secret: `ANTHROPIC_API_KEY` or
  `OPENAI_API_KEY`. Pass it with `model-key`; a key in the step `env` reaches
  every step of the Action.
- `fix` needs `contents: write` and `pull-requests: write` on the token. `issues:
write` is needed only with `issue: true`.
- Pin the Action to a full commit SHA in this mode: the step holds your key and
  pushes.
- `vendor` is `anthropic` (default) or `openai`; `base-url` points `openai` at
  any OpenAI-compatible API. `model` defaults to `claude-opus-5-5` for
  `anthropic` and is required for `openai`.
- `verify` is refused. Run your tests in your pull request workflow with
  `contents: read`.

## Inputs

| Input         | Default                  | What it does                                                                                    |
| ------------- | ------------------------ | ----------------------------------------------------------------------------------------------- |
| `path`        | `.`                      | Directory to scan, relative to the workspace.                                                   |
| `issue`       | `false`                  | `true` also keeps one issue up to date. Needs `issues: write` on the token.                     |
| `token`       | `github.token`           | Used only with `issue` or `fix`. The run summary needs no token.                                |
| `fix`         | `false`                  | `true` opens one pull request per run for a breaking mechanical change, written by your model.  |
| `vendor`      | empty (`anthropic`)      | Model vendor for `fix`: `anthropic` or `openai`.                                                |
| `model`       | empty                    | Model id as the vendor names it. Default `claude-opus-5-5` for `anthropic`; required for `openai`. |
| `base-url`    | empty                    | API base URL for an OpenAI-compatible vendor.                                                   |
| `verify`      | empty                    | Refused. With `fix`, a non-empty value fails the run before anything is generated.              |
| `model-key`   | empty                    | Model key for `fix`, passed only to the generate step.                                          |
| `group`       | set by the App's event   | For the Upseam App: the group of an `upseam-generate` or `upseam-agent` dispatch event.         |
| `agent-edits` | set by the App's event   | For the Upseam App: take the patch from your own coding agent's edits instead of a model.       |
| `check-only`  | `false`                  | For the Upseam App: check the patch with the Upseam gates without pushing.                      |

## What leaves the runner

- **Free report:** nothing. The detector runs on the runner with the change data
  bundled in the Action, and no token is passed to the step. The only network
  use is `actions/setup-node`, which may download Node.js 22 to the runner.
- **`issue: true`:** calls to the GitHub API of your own repository with `token`
  to read, create and edit the issue.
- **`fix: true`:** GitHub API calls with `token` to look up existing pull
  requests, push one branch and open a pull request, and calls to
  the model vendor you chose, with your key. The calls carry the change and the
  matched source files, with likely secrets in them replaced by placeholders
  first ([Secrets in your files](https://docs.upseam.dev/security/#secrets-in-your-files)).
  The key goes only to that vendor and is never printed or written.

The Action sends nothing to Upseam servers.

## Use with the Upseam App or your own agent

The `group`, `agent-edits` and `check-only` inputs serve the
[Upseam GitHub App](https://docs.upseam.dev/): it sends a `repository_dispatch`
event, and the Action writes the patch with your model or your own coding
agent and pushes `upseam/<group>`. The reusable workflow
`.github/workflows/agent.yml` of this repository runs your agent; see
[Bring your own agent](https://docs.upseam.dev/own-agent/).

## Support

- Documentation: <https://docs.upseam.dev/>, including
  [Run Upseam without the App](https://docs.upseam.dev/without-the-app/)
- Privacy: <https://docs.upseam.dev/privacy/>
- Security model: <https://docs.upseam.dev/security/>
- Report a vulnerability privately: <contact@upseam.dev>. Do not open a public
  issue for it.
