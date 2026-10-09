# AGENTS.md

## What This Repo Is

The RightTrain public website and status page: a Svelte 5 + Vite SPA (`src/`) served by
nginx (`nginx.conf`, `Dockerfile`), plus the Helm chart that deploys it
(`deploy/helm/righttrain-web`) and its production values (`deploy/homelab/values-homelab.yaml`).
Extracted from the `paulbailey/infra` monorepo (`apps/clearsignal/frontend`); history is preserved.

The backend is a separate private repo and the iPhone app is `righttrain-ios`. This repo is
**public**: do not commit secrets, tokens, keys or private hostnames.

## Commands

```bash
npm ci && npm run build
helm lint deploy/helm/righttrain-web -f deploy/homelab/values-homelab.yaml
helm template righttrain-web deploy/helm/righttrain-web -f deploy/homelab/values-homelab.yaml
```

There is no unit test suite; CI builds the app and lints/renders the chart.

## Deploy Model

- Releases are `vX.Y.Z` tags. `Publish Image` pushes `ghcr.io/<owner>/righttrain-web:<version>` and
  commits the new `image.tag` to `deploy/homelab/values-homelab.yaml` on `main`. Argo CD syncs from
  that commit, so rollbacks are a Git revert of the bump commit.
- The Argo `Application` lives in the cluster repo (`paulbailey/infra`), not here. It points at this
  repo's chart and values file.
- The ingresses route `/v1/journey-shares` (main host) and `/v1/status` (status host) to the backend
  Service `apiService.name` in the same namespace; renaming that Service in the backend breaks them.
- Runtime configuration (`API_BASE_URL`, `PUBLIC_WEB_BASE_URL`, `RIGHTTRAIN_APP_STORE_URL`) is injected
  at container start into `runtime-config.js`; do not bake environment-specific URLs into the build.

## Gotchas

- `src/lib/types/api.ts` is hand-written; keep it in step with the backend OpenAPI contract.
- `public/.well-known/apple-app-site-association` must match the iOS app's team/bundle identifiers.
- `public/icons/` is generated from `righttrain-ios`; edit the generator there, not the PNGs here.
