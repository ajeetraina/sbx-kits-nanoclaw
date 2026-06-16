# NanoClaw kit for Docker Sandboxes

A standalone [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/) agent kit
(`kind: agent`) for [NanoClaw](https://nanoclaw.dev)
([`nanocoai/nanoclaw`](https://github.com/nanocoai/nanoclaw)) — a lightweight,
secure AI assistant runtime driven by Claude Code. The kit clones and builds the
upstream repo at sandbox creation time and drops you into a Claude Code session
inside the checkout, with its `CLAUDE.md` and `.claude/skills/` already loaded.

Source and full docs: https://github.com/ajeetraina/sbx-kits-nanoclaw

## Image tags

| Tag      | Contents                                                        |
|----------|-----------------------------------------------------------------|
| `latest` | The NanoClaw agent kit (`spec.yaml` + README), trunk / CLI channel |

> NanoClaw trunk ships the **CLI channel** only. Chat-platform adapters
> (WhatsApp, Telegram, Discord, Slack, …) live on the upstream `channels` branch
> and are installed from inside Claude Code via `/add-<channel>` skills.

## Quick start

```console
sbx run --kit docker.io/ajeetraina777/sbx-nanoclaw-kits:latest nanoclaw
```

The first `sbx create` clones the upstream repo to `/home/agent/nanoclaw`, runs
`pnpm install` (NanoClaw is a pnpm project), rebuilds native modules, builds the
TypeScript, and stamps the upgrade marker (~2 minutes). Subsequent attaches are
immediate. If the install fails, the entrypoint prints the tail of
`~/nanoclaw-install.log` and still drops you into Claude Code so you can debug —
it never hangs.

From the session, `/setup`, `/add-whatsapp`, `/add-telegram`, `/customize`, etc.
work as documented. Upstream's own CLI is exposed as `ncl` (e.g. `ncl --help`).

## How auth works

The kit declares the same Anthropic auth wiring as the built-in `claude` agent
kit: `serviceDomains`/`serviceAuth` for `api.anthropic.com`, the OAuth flow
against `platform.claude.com`, and the `proxy-managed` sentinel pattern.
Credentials never enter the container — the sandbox proxy substitutes the real
value on egress. No `-e` flag, by design.

## Channels & egress

The kit allowlists the hosts the shipped/added channels need
(`api.telegram.org`, `*.whatsapp.com`, `*.whatsapp.net`, the npm registry, and
GitHub). In a **centrally-governed sbx environment**, egress is controlled by the
org policy instead of the kit's `allowedDomains`, so the channel hosts must be
allowlisted at the policy/Hub level (exact hosts — wildcards may not sync).

Full setup notes and the raw `spec.yaml` live on GitHub:
https://github.com/ajeetraina/sbx-kits-nanoclaw
