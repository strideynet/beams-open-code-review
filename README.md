# beams-open-code-review

Proof of concept: review each pull request with
[open-code-review](https://github.com/alibaba/open-code-review) running inside
a [Teleport Beam](https://goteleport.com/docs/beams/).

The workflow in `.github/workflows/ocr-review.yml` joins the Teleport cluster
as a Machine ID bot, creates a beam delegated only `beam-user`, copies the PR
checkout in, runs `ocr review` against the beam's built-in Anthropic endpoint,
copies the JSON result out, posts it as PR comments from the runner, and deletes
the beam. The beam never holds a GitHub token or an LLM API key.

## Setup

```sh
tctl create -f teleport/bot.yaml
tctl create -f teleport/token.yaml
```

Optionally set the `OCR_MODEL` repository variable to pick the model.

Fork PRs are skipped: they get no OIDC token, so the bot cannot join.
