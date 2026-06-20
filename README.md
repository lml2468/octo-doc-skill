# octo-doc-skill

The **tdoc agent skill** for [octo-doc](https://github.com/lml2468/octo-doc) — a
Claude Code / Codex skill that turns a prompt into a self-contained interactive
HTML document, serves it locally with text- and artifact-anchored commenting, and
publishes it to your self-hosted octo-doc server.

This repository contains only the agent-side tooling. The server it publishes to
lives in [lml2468/octo-doc](https://github.com/lml2468/octo-doc) (a Go service
backed by PostgreSQL + S3).

## Layout

```
SKILL.md            the skill definition (commands, workflow, triggers)
bin/                tdoc-new, tdoc-publish, tdoc-pull, tdoc-unpublish, tdoc-doctor
server/             local preview server (Node) + overlay.js for local rendering
.claude-plugin/     plugin + single-plugin marketplace manifests
```

## Install

As a Claude Code plugin (via the bundled marketplace):

```
/plugin marketplace add lml2468/octo-doc-skill
/plugin install octo-doc@lml2468-octo-doc
```

Or clone into your skills directory:

```bash
git clone https://github.com/lml2468/octo-doc-skill ~/.claude/skills/tdoc
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
