# octo-doc-skill

The **octo agent skill** for [octo-doc](https://github.com/Mininglamp-OSS/octo-doc)
— a Claude Code / Codex skill that turns a prompt into a self-contained interactive
HTML document, publishes it to your self-hosted octo-doc server with text- and
artifact-anchored commenting, and iterates it from the comments.

This repository contains only the agent-side authoring guide. All mechanical work
is done by the **`octo` CLI**, a single static binary built from the
[octo-doc](https://github.com/Mininglamp-OSS/octo-doc) repo (`cmd/octo`). The
server it authors against lives there too (a Go service backed by PostgreSQL + S3).

## How it fits together

```
you (a prompt)  →  this skill (authoring)  →  octo CLI (draft/publish/share)  →  octo-doc server
```

Authoring is **remote-first**: a doc lives on the server from creation as a mutable
**draft**; `octo publish` promotes the draft to an immutable version. The skill is a
thin layer — it decides slugs, generates HTML, and interprets comments; everything
else (draft, publish, share, pull, replies) is a single `octo` subcommand. There is
no local preview server and no `overlay.js` mirror: the server owns rendering.

## Compatibility

The skill tracks the octo-doc server's contract through the `octo` CLI:

- **API:** the `/v1` envelope API (`/v1/docs` incl. `/draft`, `/draft/promote`,
  `/share`; `/v1/comments`, `/v1/reactions`, `/v1/agent/replies`,
  `/v1/admin/bootstrap`). Author operations use `Authorization: Bearer <write
  token>`; responses are unwrapped from `{ "data": … }`.
- **Access:** documents are **private by default**. The write token = author; a
  per-doc share **code** (`octo share`) grants read + comment. See
  [docs/AUTH.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/AUTH.md).
- **Bootstrap:** `POST /v1/admin/bootstrap` mints the first write token, and only
  when the server was started without a static `WRITE_TOKEN`.
- **Overlay:** the server embeds octo-doc's canonical `assets/overlay.js` — there
  is no mirror to sync. `octo update` pulls a newer CLI when the server moves ahead.

## Layout

```
SKILL.md            the skill definition (commands, workflow, triggers)
references/          supporting docs the skill links to (authoring, anchoring)
templates/          the starting HTML skeleton for a new doc
```

All runtime behavior lives in the `octo` CLI, not this repo.

## Install

Clone the skill into your skills directory:

```bash
git clone https://github.com/lml2468/octo-doc-skill ~/.claude/skills/octo
# Codex: ~/.codex/skills/octo
```

Then install the `octo` CLI (or run `/octo onboard`, which does this for you):

```bash
# Prebuilt binary — pick your platform from the releases page:
#   https://github.com/Mininglamp-OSS/octo-doc/releases
# Download octo_<os>_<arch>, chmod +x, and put it on your PATH. Or, with Go:
go install github.com/Mininglamp-OSS/octo-doc/cmd/octo@latest
```

## Usage

```bash
# point the CLI at your octo-doc server
export OCTO_BASE_URL="https://docs.example.com"
export OCTO_TOKEN="<write token>"   # from: octo-doc bootstrap

/octo new "an interactive explainer of compound interest"  # → a private draft
/octo publish my-explainer          # → https://docs.example.com/d/my-explainer/v/1
/octo share my-explainer            # → a read+comment ?code= link
```

See [SKILL.md](SKILL.md) for the full command surface (`new`, `edit`, `publish`,
`share`, `pull`, `fork`, `list`, `comment`, `react`, `reply`, `doctor`,
`unpublish`, `onboard`, `update`). Config resolves from `OCTO_*` env then
`~/.octo/config.json`.

## Credits

A vendor-free reimplementation of Serena Keyitan's
[tdoc](https://github.com/serenakeyitan/tdoc), itself inspired by Jesse Pollak's
*bdocs* concept.
