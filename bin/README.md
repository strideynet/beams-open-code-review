# Prebuilt tbot

Temporary, for the PoC. Released tbot (v18) can't issue certificates for bots
with `direct_unscoped_role_assignment`, which `teleport/bot.yaml` needs, so CI
uses `tbot` built from the tenant's version (`v19.0.0-dev.beams.launch.2`),
gzipped to stay under GitHub's file size limit. Released `tsh` already supports
beams, so it comes from `teleport-actions/setup`.

```sh
CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' -o tbot ./tool/tbot
gzip -9 tbot
```

Drop this once a public tbot release supports direct role assignment.
