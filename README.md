# sbx kits for Nanoclaw

A standalone [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) kit
(`kind: sandbox`) for [NanoClaw](https://nanoclaw.dev)
([`nanocoai/nanoclaw`](https://github.com/nanocoai/nanoclaw)) - a lightweight,
secure AI assistant runtime driven by Claude Code. The kit clones and builds the
upstream repo at sandbox creation time and runs Claude Code from inside the
checkout as the entrypoint, so the project's `CLAUDE.md` and `.claude/skills/`
are loaded on attach.

> [!NOTE]
> Upstream nanoclaw trunk only ships the **CLI channel**. Chat-platform
> adapters (WhatsApp, Telegram, Discord, Slack, …) live on the
> upstream `channels` branch and are installed via `/add-<channel>`
> skills run from inside Claude Code. This kit installs trunk and
> lets you drive the rest from the shipped `claude` CLI.

## Quick start

The kit is published to Docker Hub at
[`ajeetraina777/sbx-nanoclaw-kits`](https://hub.docker.com/r/ajeetraina777/sbx-nanoclaw-kits).
Run it directly — no clone required:

```console
sbx run --kit docker.io/ajeetraina777/sbx-nanoclaw-kits:latest nanoclaw
```

### Alternative deployment

From the Git repository:

```console
sbx run --kit "git+https://github.com/ajeetraina/sbx-kits-nanoclaw.git" nanoclaw
```

From a local clone:

```console
git clone https://github.com/ajeetraina/sbx-kits-nanoclaw.git
sbx run --kit ./sbx-kits-nanoclaw/ nanoclaw
```

## What happens on first run

The first `sbx create` clones the upstream repo to `/home/agent/nanoclaw`, runs
`pnpm install` (upstream is a pnpm project, it ships `pnpm-lock.yaml`), rebuilds
native modules, runs the TypeScript build, and stamps the upgrade marker
(~2 minutes). Subsequent attaches are immediate. If the install fails, the
entrypoint prints the tail of `~/nanoclaw-install.log` and still drops you into
Claude Code so you can debug (`cd ~/nanoclaw && pnpm install`), rather than
hanging.

`sbx run` drops you into a Claude Code session whose working directory is the
nanoclaw checkout, with its `CLAUDE.md` already loaded — exactly as the official
[install guide](https://github.com/nanocoai/nanoclaw#readme) recommends. From
there, `/setup`, `/add-whatsapp`, `/add-telegram`, `/customize`, etc. work as
documented.

Upstream's own CLI is exposed as `ncl` (e.g. `ncl --help`). If you'd rather
launch the built daemon directly than enter Claude Code, exec a shell into the
sandbox from another terminal and run:

```console
nanoclaw
```

## How auth works

The kit declares the same Anthropic auth wiring as the built-in `claude` agent
kit: `serviceDomains`/`serviceAuth` for `api.anthropic.com`, the OAuth flow
against `platform.claude.com`, and the `proxy-managed` sentinel pattern.
Credentials never enter the container — the sandbox proxy substitutes the real
value on egress. No `-e` flag, by design.

## Channels & egress

The kit's `allowedDomains` allowlists the npm registry (for the install), GitHub
(for the upstream clone), `nanoclaw.dev`, and the chat-platform hosts the
shipped/added channels need (`api.telegram.org`, `*.whatsapp.com`,
`*.whatsapp.net`). In a **centrally-governed sbx environment**, egress is
controlled by the org policy instead of the kit's `allowedDomains`, so those
hosts must be allowlisted at the policy/Hub level (exact hosts — wildcards may
not sync).
