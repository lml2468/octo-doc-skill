# octo-doc-skill

The **octo agent skill** for [octo-doc](https://github.com/Mininglamp-OSS/octo-doc)
— a Claude Code / Codex skill that turns a prompt into a self-contained interactive
HTML document, serves it locally with text- and artifact-anchored commenting, and
publishes it to your self-hosted octo-doc server.

This repository contains only the agent-side authoring guide. All mechanical work
is done by the **`octo` CLI**, a single static binary built from the
[octo-doc](https://github.com/Mininglamp-OSS/octo-doc) repo (`cmd/octo`). The
server the CLI publishes to lives there too (a Go service backed by PostgreSQL + S3).

## How it fits together

```
you (a prompt)  →  this skill (authoring)  →  octo CLI (scaffold/preview/publish)  →  octo-doc server
```

The skill is a thin layer: it decides slugs, generates HTML, and interprets
comments. Everything else — creating the doc on disk, running the local preview,
publishing, pulling comments, posting agent replies — is a single `octo`
subcommand. There is **no bundled server and no `overlay.js` mirror**: the CLI
embeds the canonical overlay and renders local previews through the exact same code
the published server uses, so a local preview is byte-identical to the published
doc and can never drift.

## Compatibility

The skill tracks the octo-doc server's contract through the `octo` CLI:

- **API:** the `/v1` envelope API (`/v1/docs`, `/v1/comments`, `/v1/reactions`,
  `/v1/agent/replies`, `/v1/admin/bootstrap`). Writes use `Authorization: Bearer
  <token>`; responses are unwrapped from `{ "data": … }`. There is no login
  provider — reads and comments are public, `PRIVATE=1` gates reads.
- **Bootstrap:** `POST /v1/admin/bootstrap` mints the first write token, and only
  when the server was started without a static `WRITE_TOKEN`.
- **Overlay:** the CLI embeds octo-doc's canonical `assets/overlay.js` at build
  time — there is no mirror to sync. `octo update` pulls a newer CLI (and thus a
  newer overlay) when the server moves ahead.

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

/octo new "an interactive explainer of compound interest"
/octo publish my-explainer          # → https://docs.example.com/d/my-explainer/v/1
```

See [SKILL.md](SKILL.md) for the full command surface (`new`, `edit`, `publish`,
`pull`, `fork`, `list`, `preview`, `doctor`, `unpublish`, `onboard`, `update`).
Config resolves from `OCTO_*` env (the legacy `TDOC_*` names still work as a
fallback) then `~/.octo/config.json`.

## Credits

A vendor-free reimplementation of Serena Keyitan's
[tdoc](https://github.com/serenakeyitan/tdoc), itself inspired by Jesse Pollak's
*bdocs* concept.
