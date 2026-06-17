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

## Prerequisites

> [!IMPORTANT]
> Requires **sbx 0.32.0-rc or later**. This kit uses the v2 sandbox spec
> (`kind: sandbox`); older sbx CLIs can't parse it and fail with
> `invalid spec.yaml: field sandbox not found in type spec.specFile`. Check your
> version with `sbx version` and upgrade if needed.

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

## Troubleshooting

**`invalid spec.yaml: field sandbox not found in type spec.specFile`**

This kit uses the v2 sandbox spec (`kind: sandbox`). Older sbx CLIs don't
understand the top-level `sandbox:` block and fail to unmarshal it. Upgrade to
**sbx 0.32-rc or later** (`sbx version` to check) and re-run.

**OneCLI setup fails, or agents get `ConnectionRefused` calling the Claude API**

OneCLI's installer auto-detects its listen address from the host `docker0`
bridge, which doesn't exist inside the sandbox — so `/setup` fails with `Could
not safely determine a bind address for OneCLI`. Binding it to `127.0.0.1` fixes
the install but then **NanoClaw's nested agent containers can't reach the
gateway** (loopback inside a child container is that container, not the sandbox),
so the agent gets `ConnectionRefused` on every Claude API call.

The kit handles this automatically: `/usr/local/bin/onecli-bind-host` detects the
gateway IP of NanoClaw's docker network (the address child containers can reach)
and the entrypoint + `/etc/profile.d/onecli-bind-host.sh` export it as
`ONECLI_BIND_HOST` before OneCLI installs. On an **older published image**, do it
yourself before retrying `/setup` or `/init-onecli`:

```console
# the docker-network gateway, NOT 127.0.0.1
export ONECLI_BIND_HOST="$(ip -4 -o addr show docker0 | awk '{print $4}' | cut -d/ -f1)"
curl -fsSL https://onecli.sh/install | sh
```

If your agent containers run on a custom network (e.g. `172.18.0.0/16`), use that
network's gateway (`docker network inspect <net> -f '{{(index .IPAM.Config 0).Gateway}}'`).

**`Couldn't reach the NanoClaw service` even though the daemon is running**

The daemon's call to the local OneCLI gateway (at the bridge IP) gets captured by
the sandbox's `HTTP_PROXY` (`gateway.docker.internal:3128`) and times out, because
the gateway IP isn't in `NO_PROXY`. The kit's entrypoint adds the detected gateway
IP (plus loopback) to `NO_PROXY` before launching the daemon. On an older image,
set it yourself and restart the daemon — and use the **exact IP**, not a CIDR
(Node's `fetch`/undici ignores CIDR ranges in `NO_PROXY`):

```console
export NO_PROXY="$NO_PROXY,localhost,127.0.0.1,$(ip -4 -o addr show docker0 | awk '{print $4}' | cut -d/ -f1)"
cd ~/nanoclaw && pkill -f dist/index.js; bash start-nanoclaw.sh
```

**Setup ping fails: `NanoClaw service isn't listening on its CLI socket`**

The sandbox has no systemd/launchd, so NanoClaw's service step only writes
`start-nanoclaw.sh` without launching it and `data/cli.sock` is never created. The
kit's entrypoint now auto-starts the daemon (via `start-nanoclaw.sh`, falling
back to `node dist/index.js`) on each attach when it isn't already running. If
you're on an older image, start it manually — don't use the `systemctl --user` /
`launchctl` commands the wizard prints (neither exists in the sandbox):

```console
cd ~/nanoclaw && bash start-nanoclaw.sh   # or: nohup node dist/index.js > logs/nanoclaw.log 2>&1 &
sleep 5 && ls data/cli.sock && echo ready
```

If the socket never appears, the daemon crashed on startup — check
`~/nanoclaw/logs/nanoclaw.log` and `nanoclaw.error.log` (a common cause is the
OneCLI `ConnectionRefused` issue above).

Alternatively, skip OneCLI entirely and use the native credential proxy: put
`CLAUDE_CODE_OAUTH_TOKEN=<token>` (or `ANTHROPIC_API_KEY`) in `.env` and run
`/use-native-credential-proxy`.
