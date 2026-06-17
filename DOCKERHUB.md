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

## Prerequisites

**Requires sbx 0.32.0-rc or later.** This kit uses the v2 sandbox spec
(`kind: sandbox`); older sbx CLIs fail with `invalid spec.yaml: field sandbox not
found in type spec.specFile`. Check with `sbx version` and upgrade if needed.

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

## Troubleshooting

**`invalid spec.yaml: field sandbox not found in type spec.specFile`** — this kit
uses the v2 sandbox spec (`kind: sandbox`). Upgrade to **sbx 0.32-rc or later**
(`sbx version`) and re-run.

**OneCLI fails to bind, or agents get `ConnectionRefused` on Claude API calls** —
OneCLI auto-detects its bind address from the host `docker0` bridge (absent in
the sandbox), and `127.0.0.1` is unreachable from NanoClaw's nested agent
containers. The kit auto-detects the docker-network gateway and exports
`ONECLI_BIND_HOST` before OneCLI installs. On an older image, set it yourself:

```console
export ONECLI_BIND_HOST="$(ip -4 -o addr show docker0 | awk '{print $4}' | cut -d/ -f1)"
curl -fsSL https://onecli.sh/install | sh
```

Use a custom network's gateway if your agent containers run on one. Don't restart
with `systemctl`/`launchctl` (no systemd/launchd in-sandbox) — run the daemon
directly (`cd ~/nanoclaw && nohup node dist/index.js > logs/nanoclaw.log 2>&1 &`).
Or skip OneCLI and use the native credential proxy (`CLAUDE_CODE_OAUTH_TOKEN` in
`.env` + `/use-native-credential-proxy`).

Full setup notes and the raw `spec.yaml` live on GitHub:
https://github.com/ajeetraina/sbx-kits-nanoclaw
