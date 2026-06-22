---
name: tdoc
description: |
  Prompt-native interactive HTML docs. Generate a self-contained HTML
  document from a prompt (interactive models, SVG diagrams, simulations,
  strategy docs, research write-ups, product specs, explainer pages,
  design docs, RFCs, case studies, post-mortems, technical proposals,
  vision docs, one-pagers, decision frameworks), serve it at localhost
  with text- and artifact-anchored inline commenting, and regenerate
  new versions from comments. Publishes to a self-hosted octo-doc
  server for always-on sharing (Docker or `npx`, no Cloudflare).

  Use when asked to "write a doc", "draft this", "publish this",
  "design doc", "PRD", "one-pager", "research write-up", "case study",
  "explainer", "interactive explainer", "post-mortem", or any
  /tdoc command.

  Proactively invoke this skill (do NOT answer directly) when the
  user wants to write, draft, create, edit, publish, or share ANY
  document, write-up, explainer, or web page — EVEN IF THEY NEVER SAY
  THE WORD "tdoc". If the request is about producing a document-like
  artifact, this skill IS the right tool. Invoke it without asking
  for confirmation.

  Specific triggers (any of these → use tdoc, no need for the word "tdoc"):
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
    - any /tdoc command: new, edit, fork, list, publish, onboard, update,
      doctor, pull, unpublish

  When a request mentions an existing doc/site by name (e.g. "update the
  plaud explainer", "fix the comment on the X writeup"), that is a tdoc
  EDIT request — use this skill, run /tdoc edit-style flow.

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
  emitting it through tdoc, NOT as a raw .md file or an inline reply.

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

  HOW agents hand off a doc to tdoc (do NOT re-enter the human prompt
  flow). Generate the full HTML once, then call the programmatic entry:

    ```bash
    # Write the doc's HTML to a temp file...
    HTML_FILE=$(mktemp -t tdoc-handoff.XXXXXX.html)
    cat > "$HTML_FILE" <<'HTML'
    <!doctype html><html lang="en"><head>...</head>
    <body><div class="wrap">
      <h1>...</h1>
      <!-- your sections, with author-composed wrappers tagged
           data-tdoc-artifact wherever you want a comment surface -->
    </div></body></html>
    HTML

    # ...then hand it to tdoc. Returns the local URL on the last line,
    # plus a published URL on a second line if --publish is given.
    TDOC_NEW_CALLER=document-release \
      ~/.claude/skills/tdoc/bin/tdoc-new \
        --slug "release-notes-$(date +%Y%m%d)" \
        --title "Release notes — $(date +%Y-%m-%d)" \
        --html-file "$HTML_FILE" \
        --publish
    ```

  Set TDOC_NEW_CALLER (or CLAUDE_SKILL_NAME) to the calling skill name
  so meta.json records who scaffolded the doc. The bin script validates
  that the input is real HTML (refuses markdown by mistake), guards
  against clobbering an existing slug, and ensures the local server is
  up before returning the URL.

  Use other skills (NOT tdoc) when:
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

# tdoc — Prompt-native HTML documents

Open-source, collaborative take on Jesse Pollak's bdocs. Docs are HTML build
artifacts, not files the user maintains. Authoring interface is a prompt.
Every edit creates a new version. Comments anchor to highlighted text or to
artifacts (images, SVG, canvas, video) and are used to regenerate the next
version. Publishing pushes to a self-hosted octo-doc server (Docker or `npx`)
for always-on sharing, with optional GitHub auth gating comments.

## Storage layout

```
~/tdocs/
  <slug>/
    meta.json          # { title, created, versions: [...] }
    v1/index.html
    v2/index.html
    comments.json      # [{ id, version, anchor, text, status }]
```

Server runs at `http://localhost:7878` (override with `TDOC_PORT`) and serves:
- `/` — index of all docs
- `/d/<slug>/v/<n>` — a specific version (injects comment overlay)
- `/v1/comments` GET/POST — comment persistence (GET returns the
  `{data:[...],pagination:{...}}` envelope; POST returns `{data:{...}}`)
- `/v1/ping` — health check; responds `{"data":{"ok":true,"service":"tdoc"}}`.
  The `service` field is the identity marker — a foreign service answering 200
  on the port must NOT pass as tdoc.

All JSON endpoints speak the OCTO `/v1` wire contract: success is wrapped in a
top-level `data` (lists add `pagination`); errors are `{"error":{"code","message"}}`
with a fixed code enum. The local preview server mirrors this so the shared
overlay behaves identically against local and published docs.

## Setup check

```bash
TDOC_DIR="${TDOC_DIR:-$HOME/tdocs}"
# Resolve the skill dir for whichever host installed it: Claude Code
# (~/.claude/skills/tdoc) or Codex (~/.codex/skills/tdoc). Honor an explicit
# TDOC_SKILL_DIR override if set. Claude's location is checked first, so its
# behavior is unchanged.
SKILL_DIR="${TDOC_SKILL_DIR:-}"
[ -z "$SKILL_DIR" ] && for d in "$HOME/.claude/skills/tdoc" "$HOME/.codex/skills/tdoc"; do
  [ -f "$d/SKILL.md" ] && SKILL_DIR="$d" && break
done
SKILL_DIR="${SKILL_DIR:-$HOME/.claude/skills/tdoc}"
mkdir -p "$TDOC_DIR"

# Check server is running. Identity-check the body — 200 alone is not proof
# the answerer is tdoc; another local service can squat the port.
TDOC_PORT="${TDOC_PORT:-7878}"
PING_BODY=$(curl -sf --max-time 2 "http://localhost:${TDOC_PORT}/v1/ping" 2>/dev/null || true)
if printf '%s' "$PING_BODY" | grep -q '"service" *: *"tdoc"'; then
  echo "SERVER_OK"
elif [ -n "$PING_BODY" ]; then
  echo "PORT_FOREIGN"   # something else answers on the port — do NOT use it
else
  echo "SERVER_DOWN"
fi
```

If `PORT_FOREIGN`: another service holds port ${TDOC_PORT}. If `pgrep -f
"$SKILL_DIR/server/server.js"` finds a process, it's an outdated tdoc server —
restart it. Otherwise tell the user which process holds the port (`lsof -i
:${TDOC_PORT}`) and either free it or set `TDOC_PORT` to a free port.

If server is down, start it:
```bash
nohup node "$SKILL_DIR/server/server.js" > "$TDOC_DIR/.server.log" 2>&1 &
sleep 1
```

## Commands

### `/tdoc new <prompt>` — create a new doc

1. Pick a slug from the prompt (kebab-case, ≤4 words).
2. Create `~/tdocs/<slug>/v1/index.html` — a **fully self-contained** HTML file.
   Start from [templates/doc.html](templates/doc.html) and follow
   [references/authoring.md](references/authoring.md) (self-contained, default
   styling — do NOT re-style, required `.wrap` container, responsive defaults). If
   the prompt implies a model, simulation, or diagram, build the live thing —
   don't just describe it.
3. Write `meta.json`:
   ```json
   { "title": "...", "slug": "...", "created": "<iso>", "versions": [{ "n": 1, "created": "<iso>", "prompt": "..." }] }
   ```
4. Init `comments.json` as `[]`.
5. Open `http://localhost:7878/d/<slug>/v/1` in the browser:
   ```bash
   open "http://localhost:7878/d/<slug>/v/1"
   ```
6. Report the URL to the user.

### `bin/tdoc-new` — programmatic entry for agents in other skills

This is the contract OTHER skills (`/document-release`, `/retro`,
`/investigate`, `/cso`, `/qa-only`, `/office-hours`, `/plan-*`, etc.)
use when an agent inside them is about to emit a doc-shaped artifact.
The human-facing `/tdoc new` flow is a chat-driven prompt → HTML
generation. `bin/tdoc-new` is the other direction: the calling agent
already has the finished HTML and just wants tdoc to scaffold storage,
serve it locally, and (optionally) publish.

**When to use it:** any time inside another skill you would otherwise
have written `cat > some-report.md <<EOF ...` with more than a couple
paragraphs of structured content. Generate the doc as HTML (use the
template + styling rules from the `/tdoc new` section above), then
hand it off:

```bash
HTML_FILE=$(mktemp -t tdoc-handoff.XXXXXX.html)
cat > "$HTML_FILE" <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>...</title></head>
<body><div class="wrap">
  <h1>...</h1>
  <!-- sections; tag author-composed wrappers data-tdoc-artifact
       wherever you want a comment surface -->
</div></body>
</html>
HTML

TDOC_NEW_CALLER=document-release \
  ~/.claude/skills/tdoc/bin/tdoc-new \
    --slug "release-notes-$(date +%Y%m%d)" \
    --title "Release notes — $(date +%Y-%m-%d)" \
    --html-file "$HTML_FILE" \
    --publish
```

**Args:**
- `--slug <kebab-case>` (required) — slug for `~/tdocs/<slug>/`.
- `--title "<title>"` (required) — recorded in `meta.json`.
- `--html-file <path>` OR `--html-stdin` (required) — full HTML for v1.
- `--prompt "<one-line>"` — prompt-of-record in `meta.json` (defaults
  to `Imported via tdoc-new by <caller>`).
- `--publish` — also run `tdoc-publish` so a shareable URL is returned.
- `--open` — open the resulting URL in the default browser.
- `--quiet` — suppress informational output (the URL is still printed
  on the last line so callers can capture it).
- `--force` — overwrite an existing slug. Without this, an existing
  slug is a hard error (no silent clobber).

**Output contract:** the local URL is always the last line on stdout.
If `--publish` succeeded, the published URL appears on a second line.
This is what callers should `tail -n 1` (or `tail -n 2`) to capture.

**Guards built in:** refuses to clobber existing slugs without `--force`;
validates that input contains a `<body>` tag (catches markdown handed
in by mistake); restarts the local server if it's down so the URL is
immediately reachable.

**Set `TDOC_NEW_CALLER`** (or rely on `CLAUDE_SKILL_NAME`) so `meta.json`
records which skill scaffolded the doc — useful for later auditing or
for `/tdoc list` to show provenance.

### `/tdoc edit <slug> [<extra prompt>]` — new version from comments

You MUST report back on every open comment — applied, partial, or unclear.
This is a hard requirement, not a suggestion. The user can't tell which
comments you handled unless you reply on each one. Skipping comments
silently is the #1 source of regression complaints.

1. Read `~/tdocs/<slug>/comments.json` — filter to `status: "open"`.
2. Read latest version's `index.html`.
3. For EACH open comment, decide one of three outcomes BEFORE writing:
   - **applied** — the comment is clear and you can act on it.
   - **partial** — you applied part of it but couldn't fully address it
     (e.g. the user asked to "add a chart and explain compound interest";
     you added the chart but the explanation is shallow).
   - **question** — you can't act without clarification (the comment is
     ambiguous, contradicts another comment, or refers to content that
     doesn't exist in the current doc).
4. Regenerate as `v<n+1>/index.html` incorporating every `applied` and
   `partial` comment. A comment's anchor has:
   - `anchor.text` — the exact text the user highlighted (may span across
     paragraphs and inline elements)
   - `anchor.context_before` / `anchor.context_after` — surrounding text
     (~60 chars each side) for disambiguation when the same text appears
     multiple times
5. Append to `meta.json` versions array.
6. **For each comment, post an agent reply** so the user sees the outcome
   in the doc UI. This is mandatory.

   **For published docs** — POST to `$TDOC_BASE_URL/v1/agent/replies`
   with the write token (env `TDOC_TOKEN`, or `~/.tdoc/config.json`):
   ```bash
   BASE="${TDOC_BASE_URL:-$(jq -r .base_url ~/.tdoc/config.json)}"
   TOKEN="${TDOC_TOKEN:-$(jq -r .token ~/.tdoc/config.json)}"
   curl -sS -X POST "$BASE/v1/agent/replies" \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d "{\"slug\":\"<slug>\",\"parent_id\":\"<comment_id>\",\"text\":\"<one or two sentences>\",\"status\":\"applied\",\"applied_in\":<n+1>}"
   ```

   **For local-only docs** — POST to `http://localhost:7878/v1/agent/replies`
   (no token needed).

   The reply text should be specific:
   - applied: "Rewrote the second paragraph in English. The section heading
     is now 'What an Agent Needs'."
   - partial: "Added the chart but the compound-interest explainer is still
     basic — want me to flesh it out?"
   - question: "Two of your comments asked for different tones — formal in
     the intro and casual in section II. Which should I prioritize?"

7. Update `comments.json`: set `status: "applied"` (or leave `"open"` for
   partial/question) and `applied_in: n+1`. The agent-reply endpoint
   already flips the status server-side AND drops a status emoji on the
   parent comment (✅ applied, 🟡 partial, ❓ question), clearing any
   previous agent emoji first. You don't need to send a separate reaction
   request — the reply endpoint does it. Users see the verdict at a
   glance from the comment cards without expanding replies.

   If a comment is later re-anchored by the user (anchor moved to new
   text), the server automatically clears the agent's emoji and resets
   `status: "open"`. Re-running `/tdoc edit` will pick it up again.
6. Open `http://localhost:7878/d/<slug>/v/<n+1>`.

If there are zero open comments AND no extra prompt, ask the user what to change before doing anything.

### `/tdoc fork <slug> [<new-slug>]` — copy a doc

```bash
cp -R "$TDOC_DIR/<slug>" "$TDOC_DIR/<new-slug>"
```
Reset `comments.json` to `[]`. Update `meta.json` title to include `(fork)`.

### `/tdoc list` — show all docs

Read each `meta.json` and print: slug, title, latest version, # open comments.

### `/tdoc serve` — (re)start the server

```bash
pkill -f "$SKILL_DIR/server/server.js" 2>/dev/null
nohup node "$SKILL_DIR/server/server.js" > "$TDOC_DIR/.server.log" 2>&1 &
echo "tdoc server: http://localhost:7878"
```

### `/tdoc stop` — stop the server

```bash
pkill -f "$SKILL_DIR/server/server.js"
```

### `/tdoc publish <slug>` — publish to your self-hosted octo-doc server

Publishes the latest version of `<slug>` to a public URL on a self-hosted
[octo-doc](https://github.com/lml2468/octo-doc) server. No Cloudflare account,
no wrangler, no R2/KV — just an HTTP server you (or anyone) runs.

Local always stays $0/anonymous; publishing is opt-in. Point the CLI at your
server with two env vars (12-factor):

```bash
export TDOC_BASE_URL="https://your-host"   # or http://localhost:8080
export TDOC_TOKEN="<write token>"          # from: octo-doc bootstrap
```

To mint the first token on a fresh server:
```bash
curl -s "$TDOC_BASE_URL/v1/admin/bootstrap" | jq -r .data.token
```

The CLI saves these to `~/.tdoc/config.json` (mode 600) on first run, so later
publishes need no env. Uploads are authenticated with the Bearer token in the
`Authorization` header (never the URL). Requires `jq` and `curl`.

```bash
"$SKILL_DIR/bin/tdoc-publish" <slug>
```

Prints the published URL: `https://<host>/d/<slug>/v/<N>`.

> **Self-hosting the server:** the fastest path is `docker compose up -d` (app +
> Caddy auto-TLS). On a $5 VPS you're live in ~15 minutes — see
> [SELF_HOSTING.md](https://github.com/lml2468/octo-doc/blob/main/docs/SELF_HOSTING.md).
> For zero-Docker local use: `npx octo-doc` (SQLite + `./data`).

On published docs, comments are anonymous — same as local mode. (A future Octo
unified login will add optional per-user identity for comments.)

### `/tdoc pull <slug>` — pull comments from the published doc

Merges `~/tdocs/<slug>/comments.json` with comments collected on the server
(non-destructive; full cross-version history). Run before `/tdoc edit` to
regenerate using community feedback.

```bash
"$SKILL_DIR/bin/tdoc-pull" <slug>
```

### `/tdoc unpublish <slug>` — remove from your server

Deletes all versions, meta, and comments for `<slug>` from the server. Local
files are untouched.

```bash
"$SKILL_DIR/bin/tdoc-unpublish" <slug>
```

### `/tdoc onboard` — guided first-time setup

You are walking a user through tdoc onboarding. The user might have nothing
installed, or might be partway through. You **must** drive the flow from
`bin/tdoc-doctor` JSON output, not assume state.

**Algorithm:**

1. Run `"$SKILL_DIR/bin/tdoc-doctor"` and read its output. This is non-destructive.
2. Check local deps (node 22+, jq, curl). If any is missing, install it for the
   user via Bash (e.g. `brew install jq`), then re-run the doctor.
3. Check whether a server is configured (`TDOC_BASE_URL` / `~/.tdoc/config.json`).
   If not, ask the user whether they want to:
   - **publish to an existing octo-doc server** → ask for its URL, set
     `TDOC_BASE_URL`, mint a token with
     `curl -s "$TDOC_BASE_URL/v1/admin/bootstrap" | jq -r .data.token`, set `TDOC_TOKEN`.
   - **stand up their own server** → point them at
     [SELF_HOSTING.md](https://github.com/lml2468/octo-doc/blob/main/docs/SELF_HOSTING.md)
     (Docker compose, ~15 min on a $5 VPS) or, for a quick local test,
     `npx octo-doc` (SQLite + `./data`, prints the bootstrap path).
4. Once the doctor reports the server reachable + a token configured, offer to
   create + publish a sample doc with `/tdoc new` then `/tdoc publish`.

**Important behavioral rules:**

- NEVER skip the doctor check before suggesting a step.
- ALWAYS show the user what you're running.
- The write token is a secret — never put it in a URL or echo it into shared
  logs. It belongs in the `Authorization: Bearer` header only.

### `/tdoc update` — check for updates and pull the latest

Wraps `bin/tdoc-update`. Runs `git fetch + git merge --ff-only` against
`origin/main` of `lml2468/octo-doc`.

- `tdoc-update --check` → report-only, prints incoming commits without changing anything
- `tdoc-update` → apply, with auto-stash of local edits, **auto-restarts the running local server** so new routes / overlay code take effect

```bash
"$SKILL_DIR/bin/tdoc-update" --check    # see what's new
"$SKILL_DIR/bin/tdoc-update"            # apply
```

If the user has not yet `git clone`'d (the skill dir is not a git checkout),
the script prints a clean instruction to re-clone.

### `/tdoc doctor` — health check, no changes

Prints the doctor output. Use this when the user reports a problem to localize
which dep is missing or whether the configured server is reachable.

```bash
"$SKILL_DIR/bin/tdoc-doctor"
```

## Troubleshooting

When the user reports a problem, check these first:

- **`/v1/publish` 404, or "string did not match the expected pattern" in the Publish modal** → the running LOCAL preview server is stale (old process, doesn't have current routes). Restart it: `pkill -f "$SKILL_DIR/server/server.js" && nohup node "$SKILL_DIR/server/server.js" > "$TDOC_DIR/.server.log" 2>&1 &`.
- **Comment popup doesn't appear when selecting text** → ensure overlay.js has the fix where a drag-without-artifact-intersection falls through to the text-selection branch. Check `overlay.js` mouseup handler: the `if (dragged) { ... return; }` block must only `return` when an artifact was actually hit.
- **`/tdoc publish` says "no octo-doc server configured"** → set `TDOC_BASE_URL` (and `TDOC_TOKEN`). Mint a token on a fresh server with `curl -s "$TDOC_BASE_URL/v1/admin/bootstrap" | jq -r .data.token`. See [SELF_HOSTING.md](https://github.com/lml2468/octo-doc/blob/main/docs/SELF_HOSTING.md).
- **Publish returns 401 unauthorized** → the token is wrong or absent. The server accepts either a static `WRITE_TOKEN` (set in its env) or a bootstrap token. Confirm `TDOC_TOKEN` matches.
- **Publish returns 413 html_too_large** → the document exceeds the server's `MAX_HTML_BYTES` (default 5 MiB). Trim inline assets or raise the cap server-side.
- **Local doc URLs show the wrong content / weird JSON, or the server "is up" but docs 404** → another local service may be squatting the tdoc port. Run `curl -s http://localhost:7878/v1/ping` — if the body lacks `"service":"tdoc"`, the answerer is not tdoc. Identify the squatter with `lsof -i :7878`, then free the port or run tdoc on another port via `TDOC_PORT=<port>`.

## Authoring & references

The detailed authoring contract lives in `references/` so this file stays a thin
command surface. Read the relevant one before generating or editing a doc:

- **[references/authoring.md](references/authoring.md)** — HTML generation rules,
  the default styling contract (do NOT re-style), required container structure,
  responsive defaults, overlay-conflict rules, and comment-anchor stability.
  Start from **[templates/doc.html](templates/doc.html)**.
- **[references/anchoring.md](references/anchoring.md)** — the comment anchor JSON
  shapes (text / element / lost) and how `/tdoc edit` should interpret them.
