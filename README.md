# beams-open-code-review

Proof of concept: review each pull request with
[OpenCodeReview](https://github.com/alibaba/open-code-review) (OCR) running
inside a [Teleport Beam](https://goteleport.com/docs/beams/).

## Architecture

```
 GitHub Actions runner                         Teleport (square-lake.beams.sh)
┌──────────────────────────────┐   OIDC join  ┌──────────────────────────────┐
│ tbot: bot-ocr-reviewer       │─────────────▶│ issues short-lived certs     │
│ tsh beams add/scp/exec/rm    │              │                              │
│ GITHUB_TOKEN (posts comments)│              │  LLM proxy: injects the real │
└──────┬────────────▲──────────┘              │  Anthropic key upstream      │
       │ PR checkout│ ocr-result.json         └──────────────▲───────────────┘
       ▼            │ + session logs                         │ ANTHROPIC_BASE_URL
┌──────────────────────────────┐                             │ (VNet)
│ Beam (throwaway microVM)     │─────────────────────────────┘
│ delegated role: beam-user    │
│ ocr review --format json     │
│ no GitHub token, no API key  │
└──────────────────────────────┘
```

Per PR, `.github/workflows/ocr-review.yml`:

1. Joins Teleport as the `ocr-reviewer` bot using GitHub OIDC. No long-lived
   Teleport secret is stored in the repo.
2. Creates a fresh beam with only `beam-user` delegated, so the beam can call
   inference and manage itself, and nothing else in the cluster.
3. Copies the PR checkout in with `tsh beams scp`, installs OCR and runs
   `ocr review`. OCR talks to the beam's built-in Anthropic endpoint
   (`ANTHROPIC_BASE_URL`). Teleport's proxy adds the API key on the way out,
   so the key never exists in the beam (OCR is given a dummy token).
4. Copies the JSON result and OCR's session logs out. The runner posts the
   inline comments with its own `GITHUB_TOKEN` and uploads the logs as the
   `ocr-logs` artifact.
5. Deletes the beam, even if an earlier step failed.

The untrusted part, an LLM agent reading PR code that could carry prompt
injection, runs in the beam with no secrets to leak: no GitHub token, no LLM
key, and no Teleport access beyond `beam-user`. Everything it does is audited
under the bot's identity in Teleport.

Not isolated yet: the beam has unrestricted outbound internet, because
`tsh beams add` always creates beams with unrestricted egress. The Beams API
supports a restricted mode with an allow list, which would limit the beam to
inference only.

## Setup

```sh
tctl create -f teleport/bot.yaml
tctl create -f teleport/token.yaml
```

Optionally set the `OCR_MODEL` repository variable to pick the model.

Fork PRs are skipped: they get no OIDC token, so the bot cannot join.

`bin/tbot.gz` is a temporary prebuilt tbot, see [bin/README.md](bin/README.md).
