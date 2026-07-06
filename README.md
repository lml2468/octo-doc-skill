# octo-doc-skill

The **tdoc agent skill** for [octo-doc](https://github.com/lml2468/octo-doc) — a
Claude Code / Codex skill that turns a prompt into a self-contained interactive
HTML document, serves it locally with text- and artifact-anchored commenting, and
publishes it to your self-hosted octo-doc server.

This repository contains only the agent-side tooling. The server it publishes to
lives in [lml2468/octo-doc](https://github.com/lml2468/octo-doc) (a Go service
backed by PostgreSQL + S3).

## Compatibility

The skill is a client of the octo-doc server, so it tracks the server's contract:

- **API:** the `/v1` envelope API (`/v1/docs`, `/v1/comments`, `/v1/reactions`,
  `/v1/agent/replies`, `/v1/admin/bootstrap`). Writes use `Authorization: Bearer
  <token>`; responses are unwrapped from `{ "data": … }`. There is no login
  provider — reads and comments are public, `PRIVATE=1` gates reads.
- **Bootstrap:** `POST /v1/admin/bootstrap` mints the first write token, and only
  when the server was started without a static `WRITE_TOKEN`.
- **Overlay:** `server/overlay.js` is a byte-exact **mirror** of the server's
  `assets/overlay.js`, so local previews render identically to the published
  server. Re-sync it after the server's overlay changes:

  ```bash
  server/sync-overlay.sh   # copies from a sibling ../octo-doc checkout, else fetches main
  ```

  Last synced to octo-doc `main` @ `6ce5404` (2026-07-06). If the server's overlay
  moves ahead, run the script and commit the refreshed mirror.

## Layout

```
SKILL.md            the skill definition (commands, workflow, triggers)
references/          supporting docs the skill links to (authoring, anchoring)
templates/          the starting HTML skeleton for a new doc
bin/                tdoc-new, tdoc-publish, tdoc-pull, tdoc-unpublish, tdoc-doctor
server/             local preview server (Node) + overlay.js for local rendering
```

> `server/overlay.js` is a byte-exact mirror of the canonical
> [`octo-doc/assets/overlay.js`](https://github.com/lml2468/octo-doc/blob/main/assets/overlay.js)
> so local previews render identically to the published server. Refresh it with
> `server/sync-overlay.sh`; never edit it by hand.

## Install

Clone into your skills directory:

```bash
git clone https://github.com/lml2468/octo-doc-skill ~/.claude/skills/tdoc
# Codex: ~/.codex/skills/tdoc
```

## Usage

```bash
# point the CLI at your octo-doc server
export TDOC_BASE_URL="https://docs.example.com"
export TDOC_TOKEN="<write token>"   # from: octo-doc bootstrap

/tdoc new "an interactive explainer of compound interest"
/tdoc publish my-explainer          # → https://docs.example.com/d/my-explainer/v/1
```

See [SKILL.md](SKILL.md) for the full command surface (`new`, `edit`, `publish`,
`pull`, `fork`, `list`, `doctor`, `unpublish`, `onboard`, `update`).

## Credits

A vendor-free reimplementation of Serena Keyitan's
[tdoc](https://github.com/serenakeyitan/tdoc), itself inspired by Jesse Pollak's
*bdocs* concept.
