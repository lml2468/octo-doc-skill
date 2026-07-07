---
name: octo
description: |
  Prompt-native interactive HTML docs. Generate a self-contained HTML
  document from a prompt (interactive models, SVG diagrams, simulations,
  strategy docs, research write-ups, product specs, explainer pages,
  design docs, RFCs, case studies, post-mortems, technical proposals,
  vision docs, one-pagers, decision frameworks), publish it to a
  self-hosted octo-doc server with text- and artifact-anchored inline
  commenting, and regenerate new versions from comments. Docs are
  private by default; a per-doc share code grants read + comment
  (Docker, self-hosted).

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
           data-odoc-artifact wherever you want a comment surface -->
    </div></body></html>
    HTML

    # ...then hand it to octo. It saves the HTML as a server-side draft
    # and prints the draft URL. Follow with `octo publish <slug>` to
    # freeze it, and `octo share <slug>` for a read+comment link.
    OCTO_NEW_CALLER=document-release \
      octo new \
        --slug "release-notes-$(date +%Y%m%d)" \
        --title "Release notes — $(date +%Y-%m-%d)" \
        --html-file "$HTML_FILE"
    ```

  Set OCTO_NEW_CALLER (or CLAUDE_SKILL_NAME) to the calling skill name
  so meta.json records who scaffolded the doc. `octo new` validates
  that the input is real HTML (refuses markdown by mistake), guards
  against clobbering an existing local slug, and saves the draft on the
  server (author-only) before printing the draft URL.

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
Authoring is **remote-first**: a doc lives on a self-hosted octo-doc server from
creation as a mutable **draft**; publishing promotes the draft to an immutable
version. Comments anchor to highlighted text or to artifacts (images, SVG, canvas,
video) and drive the next iteration. Documents are **private by default** — only
the write-token holder (author) can read them; a per-doc share **code** grants
read + comment to anyone with the link.

**This skill is a thin authoring layer over the `octo` CLI.** Every mechanical
step — draft, publish, share, pull, replies — is one `octo` subcommand. The
agent's job is the creative part: turning a prompt into HTML and deciding how to
address comments. The CLI is a single static binary; no `jq`/`curl`/`node`.

## The `octo` CLI

One binary, built from the [octo-doc](https://github.com/Mininglamp-OSS/octo-doc)
repo (`cmd/octo`). Authoring and preview happen against a running octo-doc server
(a hosted instance, or the local Docker stack) — there is no local preview server.

Install it (see `/octo onboard`): download the prebuilt binary for your platform
from the [releases page](https://github.com/Mininglamp-OSS/octo-doc/releases) and
put `octo` on your PATH, or `go install github.com/Mininglamp-OSS/octo-doc/cmd/octo@latest`.

Config (env wins, then `~/.octo/config.json`):

| Var | Purpose |
| --- | ------- |
| `OCTO_BASE_URL` | server to author against (e.g. `https://docs.example.com`) |
| `OCTO_TOKEN` | write token — the **author** credential (`Authorization: Bearer`) |
| `OCTO_CODE` | a doc share **code** — the **reader** credential (for pull/comment) |
| `OCTO_DIR` | local working copy (default `~/octo-docs`) |

## Access model

- **author** = the write token. Read everything incl. drafts; publish, promote,
  delete; mint/rotate share codes.
- **reader** = a per-doc share code (`octo share`). Read published versions +
  comment/react. Never drafts or publishing.
- no credential → the server 404s (a private doc never confirms it exists).

Browsers carry the code as `?code=` (exchanged for an HttpOnly cookie); the CLI
sends the credential as `Authorization: Bearer`. Full model:
[docs/AUTH.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/AUTH.md).

## Storage layout (local working copy)

```
~/octo-docs/
  <slug>/
    meta.json          # { title, slug, created, versions: [...] }
    v1/index.html      # published-version sources
    draft/index.html   # the current draft's source (mirrors the server draft)
    comments.json      # pulled comments (cache of the server's, for edit)
```

The server is the source of truth; the local copy is the HTML the agent generates
and the pulled comments it edits against.

## Setup check

```bash
command -v octo >/dev/null 2>&1 || echo "octo CLI not found — run /octo onboard"
octo doctor   # checks the CLI + whether the configured server is reachable
```

## Commands

### `/octo new <prompt>` — create a new doc

1. Pick a slug from the prompt (kebab-case, ≤4 words).
2. Author a **fully self-contained** HTML file. Start from
   [templates/doc.html](templates/doc.html) and follow
   [references/authoring.md](references/authoring.md) (self-contained, default
   styling — do NOT re-style, required `.wrap` container, responsive defaults). If
   the prompt implies a model, simulation, or diagram, build the live thing —
   don't just describe it.
3. Hand the HTML to the CLI, which saves it as a **draft on the server** (private,
   author-only), keeps a local working copy, and prints the draft URL:
   ```bash
   octo new --slug <slug> --title "<title>" --html-file <path> --prompt "<the prompt>" --open
   ```
   (`--html-stdin` pipes the HTML instead of a temp file. `--open` opens the draft
   in a browser — the URL carries the write token as `?code=`, exchanged for a
   cookie so the author can view the private draft.)
4. Report the draft URL. When the doc is ready, `/octo publish` freezes it.

`octo new` is also the **programmatic entry other skills use** for agent-to-agent
doc handoff — see the description block above. It validates the input is real HTML
(refuses markdown), never clobbers an existing local slug without `--force`, and
prints the draft URL last so callers can `tail -n 1` it.

### `/octo edit <slug> [<extra prompt>]` — new version from comments

You MUST report back on every open comment — applied, partial, or unclear.
This is a hard requirement, not a suggestion. The user can't tell which
comments you handled unless you reply on each one. Skipping comments
silently is the #1 source of regression complaints.

1. Pull the latest comments so you edit against real feedback, then read them:
   ```bash
   octo pull <slug>
   ```
   Read `~/octo-docs/<slug>/comments.json` and filter to `status: "open"`.
2. Read the latest published version's `index.html` (or the current `draft/`).
3. For EACH open comment, decide one of three outcomes BEFORE writing:
   - **applied** — the comment is clear and you can act on it.
   - **partial** — you applied part of it but couldn't fully address it.
   - **question** — you can't act without clarification (ambiguous, contradictory,
     or refers to content that doesn't exist).
4. Regenerate the HTML incorporating every `applied` and `partial` comment. A
   comment's anchor has:
   - `anchor.text` — the exact highlighted text (may span paragraphs/inline elements)
   - `anchor.context_before` / `anchor.context_after` — ~60 chars each side for
     disambiguation when the same text appears more than once
5. Save the new iteration as the doc's **draft** (overwrites the current draft):
   ```bash
   octo version-add --slug <slug> --html-file <new-html> --prompt "<what changed>"
   ```
6. **For each comment, post an agent reply** so the user sees the outcome in the
   doc UI. This is mandatory:
   ```bash
   octo reply --slug <slug> --parent <comment_id> \
     --text "<one or two sentences>" --status applied --applied-in <n+1>
   ```
   The reply text should be specific:
   - applied: "Rewrote the second paragraph in English; the heading is now 'What an Agent Needs'."
   - partial: "Added the chart but the compound-interest explainer is still basic — flesh it out?"
   - question: "Two comments asked for different tones — formal intro vs casual §II. Which wins?"

   The reply flips the comment's status server-side AND drops a status emoji on the
   parent (✅ applied, 🟡 partial, ❓ question), clearing any prior agent emoji. No
   separate reaction request needed. If the user later re-anchors a comment, the
   server resets it to `open` and `/octo edit` picks it up again.
7. When the iteration is ready, `octo publish <slug>` promotes the draft to the
   next immutable version.

If there are zero open comments AND no extra prompt, ask the user what to change first.

### `/octo fork <slug> [<new-slug>]` — copy a doc

```bash
octo fork <slug> [<new-slug>]
```
Copies the local working copy under a new slug, resets its comments, and marks the
title `(fork)`. Defaults the new slug to `<slug>-fork`.

### `/octo list` — show all docs

```bash
octo list
```
Prints each local doc's slug, latest version, open-comment count, and title.

### `/octo publish <slug>` — promote the draft to an immutable version

Promotes the doc's current server-side draft to a new permanent version.

```bash
export OCTO_BASE_URL="https://your-host"   # or http://localhost:8080
export OCTO_TOKEN="<write token>"          # from: octo-doc bootstrap
octo publish <slug>                        # → https://<host>/d/<slug>/v/<N>
```

The CLI saves `{base_url, token}` to `~/.octo/config.json` (mode 600) on first run,
so later commands need no env. The write token is sent as `Authorization: Bearer`
(never in a URL).

> **Self-hosting the server:** `docker compose up -d` (app + Caddy auto-TLS). ~15
> min on a $5 VPS — see
> [SELF_HOSTING.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/SELF_HOSTING.md).

### `/octo share <slug>` — make it readable + commentable

New docs are **private** (author-only). To let others read and comment, mint a
share code and hand out the link:

```bash
octo share <slug>            # prints  .../d/<slug>/v/<N>?code=<code>
octo share <slug> --revoke   # clear the code — existing links stop working
```

Re-running rotates the code (old links stop working). Anyone with a `?code=` link
gets read + comment; it never grants publishing or deletion.

### `/octo pull <slug>` — pull comments from the server

Merges `~/octo-docs/<slug>/comments.json` with the server's comments
(non-destructive; full history; a `.bak` is written before merge). Run before
`/octo edit` to regenerate against real feedback.

```bash
octo pull <slug>
```

### `/octo unpublish <slug>` — remove from the server

Deletes all versions, the draft, and comments for `<slug>` from the server. Local
files are untouched.

```bash
octo unpublish <slug>
```

### `/octo onboard` — guided first-time setup

You are walking a user through octo onboarding. Drive the flow from `octo doctor`
output, not assumed state.

1. Check the CLI is installed: `command -v octo`. If not, install it — download the
   release binary for the user's platform from
   [releases](https://github.com/Mininglamp-OSS/octo-doc/releases) and put it on
   PATH, or `go install github.com/Mininglamp-OSS/octo-doc/cmd/octo@latest`.
2. Run `octo doctor` (non-destructive).
3. Check whether a server is configured (`OCTO_BASE_URL` / `~/.octo/config.json`).
   If not, ask the user whether to:
   - **use an existing octo-doc server** → ask for its URL, set `OCTO_BASE_URL`,
     mint a token with
     `curl -sS -X POST "$OCTO_BASE_URL/v1/admin/bootstrap" | jq -r .data.token`,
     set `OCTO_TOKEN`.
   - **stand up their own** →
     [SELF_HOSTING.md](https://github.com/Mininglamp-OSS/octo-doc/blob/main/docs/SELF_HOSTING.md).
4. Once `octo doctor` reports the server reachable + a token configured, offer to
   create + publish a sample doc: `/octo new` → `/octo publish` → `/octo share`.

- NEVER skip the doctor check before suggesting a step.
- ALWAYS show the user what you're running.
- The write token is a secret — it belongs in the `Authorization: Bearer` header,
  not a shared log.

### `/octo update` — update the CLI to the latest release

```bash
octo update --check    # report current-vs-latest without installing
octo update            # download + checksum-verify + replace the binary
```

`octo update` fetches the latest
[release](https://github.com/Mininglamp-OSS/octo-doc/releases), verifies against
`SHA256SUMS`, and atomically replaces the running binary.

### `/octo doctor` — health check, no changes

```bash
octo doctor
```

Prints the CLI version + doc store and (if configured) the remote server's
reachability + whether a write token is set.

## Troubleshooting

- **`octo: command not found`** → not installed / not on PATH. Run `/octo onboard`.
- **A doc URL 404s in the browser** → docs are private by default. Open it with a
  share link (`octo share <slug>` → `?code=` URL), or as the author. A wrong/rotated
  code also 404s.
- **`octo new`/`publish` says "no octo-doc server configured"** → set
  `OCTO_BASE_URL` (and `OCTO_TOKEN`). Mint a token with
  `curl -sS -X POST "$OCTO_BASE_URL/v1/admin/bootstrap" | jq -r .data.token`.
- **401 unauthorized** on an author op → the write token is wrong or absent.
  Confirm `OCTO_TOKEN` matches the server's `WRITE_TOKEN` or a bootstrap token.
- **413 html_too_large** → the doc exceeds `MAX_HTML_BYTES` (default 5 MiB).
- **Comment/overlay behaves oddly** → the overlay ships in the CLI + server; run
  `octo update` for the latest, and make sure the server is up to date too.

## Authoring & references

The detailed authoring contract lives in `references/` so this file stays a thin
command surface. Read the relevant one before generating or editing a doc:

- **[references/authoring.md](references/authoring.md)** — HTML generation rules,
  the default styling contract (do NOT re-style), required container structure,
  responsive defaults, overlay-conflict rules, and comment-anchor stability.
  Start from **[templates/doc.html](templates/doc.html)**.
- **[references/anchoring.md](references/anchoring.md)** — the comment anchor JSON
  shapes (text / element / lost) and how `/octo edit` should interpret them.
