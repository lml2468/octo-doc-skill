---
name: octo
description: |
  Prompt-native interactive HTML docs. Generate a self-contained HTML
  document from a prompt (interactive models, SVG diagrams, simulations,
  strategy docs, research write-ups, product specs, explainer pages,
  design docs, RFCs, case studies, post-mortems, technical proposals,
  vision docs, one-pagers, decision frameworks), serve it at localhost
  with text- and artifact-anchored inline commenting, and regenerate
  new versions from comments. Publishes to a self-hosted octo-doc
  server for always-on sharing (Docker, no Cloudflare).

  Use when asked to "write a doc", "draft this", "publish this",
  "design doc", "PRD", "one-pager", "research write-up", "case study",
  "explainer", "interactive explainer", "post-mortem", or any
  /octo command.

  Proactively invoke this skill (do NOT answer directly) when the
  user wants to write, draft, create, edit, publish, or share ANY
  document, write-up, explainer, or web page — EVEN IF THEY NEVER SAY
  THE WORD "octo". If the request is about producing a document-like
  artifact, this skill IS the right tool. Invoke it without asking
  for confirmation.

  Specific triggers (any of these → use octo, no need for the word "octo"):
    - "write/draft/make a doc", "write something up", "document this"
    - "publish this", "share this writeup", "make it shareable"
    - "write/draft/make a research doc", "research write-up", "research summary"
    - "product doc", "product spec", "PRD", "one-pager", "vision doc"
    - "design doc", "RFC", "technical proposal", "architecture doc"
    - "explainer", "explain X visually", "interactive explainer", "concept doc"
    - "strategy doc", "decision framework", "post-mortem", "retro doc"
    - "case study", "field report", "investigation doc"
    - "make a doc/page that has [a chart / simulation / slider / model / diagram]"
    - "create a webpage to explain X", "publish this as HTML"
    - "I want people to comment on this", "let people read and comment"
    - editing or updating an existing doc/site/page the user previously made
    - any /octo command: new, edit, fork, list, publish, onboard, update,
      doctor, pull, unpublish

  When a request mentions an existing doc/site by name (e.g. "update the
  plaud explainer", "fix the comment on the X writeup"), that is an octo
  EDIT request — use this skill, run /octo edit-style flow.

  Use this INSTEAD of generating raw markdown / Google Docs / Notion-style
  content when the user wants:
    - something interactive (charts, simulations, sliders, live demos)
    - something shareable via URL with commenting
    - something that benefits from being a real HTML page rather than text
    - any document where the artifacts (images, diagrams, code blocks, video)
      should be commentable alongside the prose

  ALSO USE WHEN NO HUMAN ASKED — agent-originated docs:
  This skill is the right surface for ANY doc-shaped artifact, including
  ones YOU (the agent) decide to emit mid-flow inside another skill's
  workflow. If you are about to produce a multi-paragraph standalone
  document — release notes, a retro, a post-mortem, an investigation
  report, a security audit, a QA report, a design critique, an
  architecture review, a meeting summary, a research write-up — and no
  upstream instruction said "write it to a file named X", default to
  emitting it through octo, NOT as a raw .md file or an inline reply.

  Concrete triggers for agent-to-agent doc handoff (no human prompt
  required):
    - You're inside /document-release and the output is "the doc"
    - You're inside /retro and the output is the weekly retrospective
    - You're inside /investigate or /cso and you're about to write up
      findings as a multi-section report
    - You're inside /qa-only and you're about to write a structured
      bug report with screenshots
    - You're inside /office-hours or /plan-* and you're about to save
      a design doc
    - Any time you would otherwise have written `cat > something.md`
      with more than a few paragraphs of structured content

  HOW agents hand off a doc to octo (do NOT re-enter the human prompt
  flow). Generate the full HTML once, then call the CLI's programmatic
  entry:

    ```bash
    # Write the doc's HTML to a temp file...
    HTML_FILE=$(mktemp -t octo-handoff.XXXXXX.html)
    cat > "$HTML_FILE" <<'HTML'
    <!doctype html><html lang="en"><head>...</head>
    <body><div class="wrap">
      <h1>...</h1>
      <!-- your sections, with author-composed wrappers tagged
           data-tdoc-artifact wherever you want a comment surface -->
    </div></body></html>
    HTML

    # ...then hand it to octo. Returns the local URL on the last line,
    # plus a published URL on a second line if --publish is given.
    OCTO_NEW_CALLER=document-release \
      octo new \
        --slug "release-notes-$(date +%Y%m%d)" \
        --title "Release notes — $(date +%Y-%m-%d)" \
        --html-file "$HTML_FILE" \
        --publish
    ```

  Set OCTO_NEW_CALLER (or CLAUDE_SKILL_NAME) to the calling skill name
  so meta.json records who scaffolded the doc. `octo new` validates
  that the input is real HTML (refuses markdown by mistake), guards
  against clobbering an existing slug, and ensures the local preview is
  up before returning the URL.

  Use other skills (NOT octo) when:
    - The user explicitly wants markdown / .md output
    - The user wants slides (use scientific-slides or paper-2-web)
    - The user is editing an existing repo's README/docs in place
    - The "doc" is a single paragraph or one-line update — that's a
      conversational reply, not a doc-shaped artifact
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
triggers:
  - write a doc
  - draft a doc
  - make a doc
  - write something up
  - document this
  - publish this
  - share this writeup
  - make it shareable
  - research write-up
  - research summary
  - product spec
  - PRD
  - one-pager
  - vision doc
  - design doc
  - RFC
  - technical proposal
  - architecture doc
  - explainer
  - explain visually
  - interactive explainer
  - strategy doc
  - decision framework
  - post-mortem
  - retro doc
  - case study
  - field report
  - investigation doc
  - create a webpage
  - publish as HTML
  - let people read and comment
---

# octo — Prompt-native HTML documents

Open-source, collaborative take on Jesse Pollak's bdocs. Docs are HTML build
artifacts, not files the user maintains. Authoring interface is a prompt.
Every edit creates a new version. Comments anchor to highlighted text or to
artifacts (images, SVG, canvas, video) and are used to regenerate the next
version. Publishing pushes to a self-hosted octo-doc server (Docker) for
always-on sharing; writes need a bearer token, reads and comments are public
by default (set `PRIVATE=1` to require the token for reads too).

**This skill is a thin authoring layer over the `octo` CLI.** Every mechanical
step — scaffolding, local preview, publish, pull, replies — is one `octo`
subcommand. The agent's job is the creative part: turning a prompt into HTML and
deciding how to address comments. There is no bash plumbing, no Node server, and
no `jq`/`curl`/`python3` dependency; the CLI is a single static binary.

## The `octo` CLI

One binary, built from the [octo-doc](https://github.com/Mininglamp-OSS/octo-doc)
repo (`cmd/octo`). It embeds the canonical `overlay.js` and renders local previews
through the **same** code the published server uses — so a local preview is
byte-identical to the published doc, with no mirrored overlay to keep in sync.

Install it (see `/octo onboard`): download the prebuilt binary for your platform
from the [releases page](https://github.com/Mininglamp-OSS/octo-doc/releases) and
put `octo` on your PATH, or `go install github.com/Mininglamp-OSS/octo-doc/cmd/octo@latest`.

Config (env wins, then `~/.octo/config.json`; the legacy `TDOC_*` names and
`~/.tdoc/config.json` are still read as fallbacks):

| Var | Purpose |
| --- | ------- |
| `OCTO_BASE_URL` | server to publish to (e.g. `https://docs.example.com`) |
| `OCTO_TOKEN` | write token (sent as `Authorization: Bearer`) |
| `OCTO_DIR` | local doc store (default `~/octo-docs`, else an existing `~/tdocs`) |
| `OCTO_PORT` | local preview port (default `7878`) |

## Storage layout

```
~/octo-docs/
  <slug>/
    meta.json          # { title, slug, created, versions: [...] }
    v1/index.html
    v2/index.html
    comments.json      # [{ id, version, anchor, text, status, replies, reactions }]
```

The preview server runs at `http://localhost:7878` (override with `OCTO_PORT`) and
serves:
- `/` — index of all docs
- `/d/<slug>/v/<n>` — a specific version (injects the comment overlay)
- `/v1/comments` GET/POST/PATCH/DELETE — comment persistence (envelope-wrapped)
- `/v1/agent/replies` POST — agent replies (drives the edit workflow)
- `/v1/reactions` POST — emoji reactions
- `/v1/ping` — health check; responds `{"data":{"ok":true,"service":"octo"}}`.
  The `service` field is the identity marker — a foreign service answering 200
  on the port must NOT pass as octo.

All JSON endpoints speak the OCTO `/v1` wire contract: success is wrapped in a
top-level `data` (lists add `pagination`); errors are `{"error":{"code","message"}}`
with a fixed code enum. The preview server mirrors this so the shared overlay
behaves identically against local and published docs.

## Setup check

```bash
# Is the CLI installed?
command -v octo >/dev/null 2>&1 || echo "octo CLI not found — run /octo onboard"

# Is the local preview up and is it ours? `octo preview status` identity-checks
# the port (200 alone is not proof — another local service can squat it).
octo preview status
```

If the preview is down, start it (idempotent — a no-op if already healthy):
```bash
octo preview start
```

If the port is held by a foreign service, `octo preview start` refuses and tells
you to free it or set `OCTO_PORT` to a different port.

## Commands

### `/octo new <prompt>` — create a new doc

1. Pick a slug from the prompt (kebab-case, ≤4 words).
2. Author a **fully self-contained** HTML file for v1. Start from
   [templates/doc.html](templates/doc.html) and follow
   [references/authoring.md](references/authoring.md) (self-contained, default
   styling — do NOT re-style, required `.wrap` container, responsive defaults). If
   the prompt implies a model, simulation, or diagram, build the live thing —
   don't just describe it.
3. Hand the HTML to the CLI, which scaffolds `meta.json` + `comments.json`, starts
   the preview if needed, and prints the local URL:
   ```bash
   octo new --slug <slug> --title "<title>" --html-file <path> --prompt "<the prompt>" --open
   ```
   (Use `--html-stdin` to pipe the HTML instead of writing a temp file.)
4. Report the printed URL to the user.

`octo new` is also the **programmatic entry other skills use** for
agent-to-agent doc handoff — see the description block above. It validates the
input is real HTML (refuses markdown), never clobbers an existing slug without
`--force`, and prints the local URL last (plus a published URL on a second line
if `--publish` is given) so callers can `tail -n 1`/`tail -n 2` to capture it.

### `/octo edit <slug> [<extra prompt>]` — new version from comments

You MUST report back on every open comment — applied, partial, or unclear.
This is a hard requirement, not a suggestion. The user can't tell which
comments you handled unless you reply on each one. Skipping comments
silently is the #1 source of regression complaints.

1. Pull the latest comments (if the doc is published) so you edit against
   community feedback, then read them:
   ```bash
   octo pull <slug>    # published docs only; no-op message if not published
   ```
   Read `~/octo-docs/<slug>/comments.json` and filter to `status: "open"`.
2. Read the latest version's `index.html`.
3. For EACH open comment, decide one of three outcomes BEFORE writing:
   - **applied** — the comment is clear and you can act on it.
   - **partial** — you applied part of it but couldn't fully address it
     (e.g. the user asked to "add a chart and explain compound interest";
     you added the chart but the explanation is shallow).
   - **question** — you can't act without clarification (the comment is
     ambiguous, contradicts another comment, or refers to content that
     doesn't exist in the current doc).
4. Regenerate the HTML incorporating every `applied` and `partial` comment. A
   comment's anchor has:
   - `anchor.text` — the exact text the user highlighted (may span across
     paragraphs and inline elements)
   - `anchor.context_before` / `anchor.context_after` — surrounding text
     (~60 chars each side) for disambiguation when the same text appears
     multiple times
5. Add the new version with the CLI (writes `v<n+1>/index.html`, appends to
   `meta.json`, prints the new URL):
   ```bash
   octo version-add --slug <slug> --html-file <new-html> --prompt "<what changed>"
   ```
6. **For each comment, post an agent reply** so the user sees the outcome in the
   doc UI. This is mandatory. Use `octo reply` — it targets the local preview by
   default, or the configured server with `--remote` (use `--remote` for a
   published doc so the reply lands where readers see it):
   ```bash
   octo reply --slug <slug> --parent <comment_id> \
     --text "<one or two sentences>" --status applied --applied-in <n+1>
   # published doc: add --remote
   ```

   The reply text should be specific:
   - applied: "Rewrote the second paragraph in English. The section heading
     is now 'What an Agent Needs'."
   - partial: "Added the chart but the compound-interest explainer is still
     basic — want me to flesh it out?"
   - question: "Two of your comments asked for different tones — formal in
     the intro and casual in section II. Which should I prioritize?"

   The reply endpoint flips the comment's status server-side AND drops a status
   emoji on the parent comment (✅ applied, 🟡 partial, ❓ question), clearing any
   previous agent emoji first. You don't need a separate reaction request. Users
   see the verdict at a glance from the comment cards without expanding replies.

   If a comment is later re-anchored by the user (anchor moved to new text), the
   server automatically clears the agent's emoji and resets `status: "open"`.
   Re-running `/octo edit` will pick it up again.
7. Open `http://localhost:7878/d/<slug>/v/<n+1>` (the URL `octo version-add`
   printed).

If there are zero open comments AND no extra prompt, ask the user what to change before doing anything.

### `/octo fork <slug> [<new-slug>]` — copy a doc

```bash
octo fork <slug> [<new-slug>]
```
Copies the doc under a new slug, resets its comments to `[]`, and marks the title
`(fork)`. Defaults the new slug to `<slug>-fork`.

### `/octo list` — show all docs

```bash
octo list
```
Prints each doc's slug, latest version, open-comment count, and title.

### `/octo preview` — manage the local preview server

```bash
octo preview start     # start in the background (idempotent), print the URL
octo preview status    # is it up, and is it ours?
octo preview stop      # stop the background server
octo preview serve     # run in the foreground (blocks; for debugging)
```

### `/octo publish <slug>` — publish to your self-hosted octo-doc server

Publishes every version of `<slug>` to a public URL on a self-hosted
[octo-doc](https://github.com/Mininglamp-OSS/octo-doc) server. No Cloudflare
account, no wrangler, no R2/KV — just an HTTP server you (or anyone) runs.

Local always stays $0/anonymous; publishing is opt-in. Point the CLI at your
server with two env vars (12-factor):

```bash
export OCTO_BASE_URL="https://your-host"   # or http://localhost:8080
export OCTO_TOKEN="<write token>"          # from: octo-doc bootstrap
```

To mint the first token on a fresh server:
```bash
curl -sS -X POST "$OCTO_BASE_URL/v1/admin/bootstrap" | jq -r .data.token
```

The CLI saves these to `~/.octo/config.json` (mode 600) on first run, so later
publishes need no env. Uploads are authenticated with the Bearer token in the
`Authorization` header (never the URL).

```bash
octo publish <slug>
```

Prints the published URL: `https://<host>/d/<slug>/v/<N>`.

> **Self-hosting the server:** the fastest path is `docker compose up -d` (app +
> Caddy auto-TLS). On a $5 VPS you're live in ~15 minutes — see
> [SELF_HOSTING.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/SELF_HOSTING.md).

On published docs, comments are anonymous — same as local mode. (A future Octo
unified login will add optional per-user identity for comments.)

### `/octo pull <slug>` — pull comments from the published doc

Merges `~/octo-docs/<slug>/comments.json` with comments collected on the server
(non-destructive; full cross-version history; a `.bak` is written before merge).
Run before `/octo edit` to regenerate using community feedback.

```bash
octo pull <slug>
```

### `/octo unpublish <slug>` — remove from your server

Deletes all versions, meta, and comments for `<slug>` from the server. Local
files are untouched.

```bash
octo unpublish <slug>
```

### `/octo onboard` — guided first-time setup

You are walking a user through octo onboarding. The user might have nothing
installed, or might be partway through. Drive the flow from `octo doctor` output,
not assumed state.

**Algorithm:**

1. Check the CLI is installed: `command -v octo`. If not, install it — download
   the release binary for the user's platform from
   [releases](https://github.com/Mininglamp-OSS/octo-doc/releases) and put it on
   PATH, or `go install github.com/Mininglamp-OSS/octo-doc/cmd/octo@latest` if Go
   is present. Then re-check.
2. Run `octo doctor` and read its output (non-destructive).
3. Check whether a server is configured (`OCTO_BASE_URL` / `~/.octo/config.json`).
   If not, ask the user whether they want to:
   - **publish to an existing octo-doc server** → ask for its URL, set
     `OCTO_BASE_URL`, mint a token with
     `curl -sS -X POST "$OCTO_BASE_URL/v1/admin/bootstrap" | jq -r .data.token`,
     set `OCTO_TOKEN`.
   - **stand up their own server** → point them at
     [SELF_HOSTING.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/SELF_HOSTING.md)
     (Docker compose, ~15 min on a $5 VPS).
4. Once `octo doctor` reports the server reachable + a token configured, offer to
   create + publish a sample doc with `/octo new` then `/octo publish`.

**Important behavioral rules:**

- NEVER skip the doctor check before suggesting a step.
- ALWAYS show the user what you're running.
- The write token is a secret — never put it in a URL or echo it into shared
  logs. It belongs in the `Authorization: Bearer` header only.

### `/octo update` — update the CLI to the latest release

```bash
octo update --check    # report current-vs-latest without installing
octo update            # download + checksum-verify + replace the binary
```

`octo update` fetches the latest [release](https://github.com/Mininglamp-OSS/octo-doc/releases),
verifies the download against the release `SHA256SUMS`, and atomically replaces
the running binary. Restart any foreground `octo preview serve` afterward so the
new embedded overlay takes effect (a backgrounded `octo preview start` picks it up
on its next start).

### `/octo doctor` — health check, no changes

```bash
octo doctor
```

Prints the CLI version + doc store, the local preview status, and (if configured)
the remote server's reachability + whether a write token is set. Use this when the
user reports a problem to localize which piece is missing.

## Troubleshooting

When the user reports a problem, check these first:

- **`octo: command not found`** → the CLI isn't installed or isn't on PATH. Run
  `/octo onboard` (downloads the release binary), or add its directory to PATH.
- **Comment popup doesn't appear when selecting text** → the overlay is embedded
  in the CLI; update it with `octo update` to get the latest overlay, then restart
  the preview (`octo preview stop && octo preview start`).
- **`octo publish` says "no octo-doc server configured"** → set `OCTO_BASE_URL`
  (and `OCTO_TOKEN`). Mint a token on a fresh server with
  `curl -sS -X POST "$OCTO_BASE_URL/v1/admin/bootstrap" | jq -r .data.token`. See
  [SELF_HOSTING.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/SELF_HOSTING.md).
- **Publish returns 401 unauthorized** → the token is wrong or absent. The server
  accepts either a static `WRITE_TOKEN` (set in its env) or a bootstrap token.
  Confirm `OCTO_TOKEN` matches.
- **Publish returns 413 html_too_large** → the document exceeds the server's
  `MAX_HTML_BYTES` (default 5 MiB). Trim inline assets or raise the cap server-side.
- **Local doc URLs show wrong content / the port "is up" but docs 404** → another
  local service may be squatting the octo port. Run `octo preview status` — if it
  reports "foreign service", identify the squatter with `lsof -i :7878`, then free
  the port or run octo on another port via `OCTO_PORT=<port>`.

## Authoring & references

The detailed authoring contract lives in `references/` so this file stays a thin
command surface. Read the relevant one before generating or editing a doc:

- **[references/authoring.md](references/authoring.md)** — HTML generation rules,
  the default styling contract (do NOT re-style), required container structure,
  responsive defaults, overlay-conflict rules, and comment-anchor stability.
  Start from **[templates/doc.html](templates/doc.html)**.
- **[references/anchoring.md](references/anchoring.md)** — the comment anchor JSON
  shapes (text / element / lost) and how `/octo edit` should interpret them.
