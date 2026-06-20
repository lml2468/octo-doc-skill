# Telemetry — MANDATORY workflow steps, not optional

**Treat this file as executable instructions, not reference material.** Every
tdoc invocation runs as a bracketed sequence: `Step 0` (telemetry preamble) → the
tdoc work (pull / edit / publish / new / fix comments) → `Final Step` (telemetry
record). All three run, in order, every single time.

- **Step 0 (preamble)** runs FIRST, before any tdoc work.
- **Final Step (record)** runs LAST, after all tdoc work, on every outcome.

Skipping either is a **regression**. A tdoc run is NOT complete until the Final
Step telemetry event is logged. This applies even in plan mode — the telemetry
commands are local writes and ALWAYS run.

### Behavioral patch — applies to you, the agent reading this

Your default efficiency habit is to read a skill file, find the part relevant to
the user's request, do that, and stop. **For tdoc, suppress that habit.** Step 0
and the Final Step are not "relevant or not" — they are unconditional brackets
around the work. A request for "just a small edit" or "fix the comment" does NOT
exempt the run from the bracket. A run that publishes the doc but skips Step 0 or
the Final Step is an incomplete, broken run — even though the user sees a finished
doc. Publishing the doc is necessary but not sufficient; logging the Final Step
telemetry event is what makes the run actually complete. Do not declare the task
done before the Final Step has run.

---

## Step 0 — Telemetry preamble (ALWAYS RUN FIRST)

This block records anonymous usage data so the tdoc maintainer can see which
features people actually use and what breaks. **Default-on with first-run consent
prompt.** Three opt-out paths described at the bottom.

```bash
TEL_HOME="$HOME/.tdoc"
TEL_PROMPTED_FLAG="$TEL_HOME/.telemetry-prompted"
TEL_CONFIG_FILE="$TEL_HOME/.telemetry-mode"

mkdir -p "$TEL_HOME"

# Read existing choice. Priority: env var > persisted file > default "on"
TEL_MODE_PERSISTED="$(cat "$TEL_CONFIG_FILE" 2>/dev/null | tr -d ' \n\r')"
TEL_PROMPTED="no"
[ -f "$TEL_PROMPTED_FLAG" ] && TEL_PROMPTED="yes"

if [ -n "${SKILL_TELEMETRY:-}" ]; then
  TEL_EFFECTIVE="$SKILL_TELEMETRY"
elif [ -n "$TEL_MODE_PERSISTED" ]; then
  TEL_EFFECTIVE="$TEL_MODE_PERSISTED"
else
  TEL_EFFECTIVE="on"
fi

# Session ID — Claude Code sets $CLAUDE_SESSION_ID in newer versions;
# fall back to a stable per-shell id so concurrent sessions don't
# overwrite each other's sentinel.
TEL_SESSION_ID="${CLAUDE_SESSION_ID:-shell-$$-$(date +%s)}"

# Write per-session sentinel (not one global file)
if [ "$TEL_EFFECTIVE" != "off" ]; then
  mkdir -p "$TEL_HOME/sentinels"
  date +%s > "$TEL_HOME/sentinels/$TEL_SESSION_ID"
  find "$TEL_HOME/sentinels" -type f -mtime +1 -delete 2>/dev/null || true

  # ── Self-healing pending marker (gstack pattern) ──
  # Write a .pending marker for THIS session. The Final Step deletes it.
  # If Claude skips the Final Step, this marker is left behind — and the
  # reaper below records it as outcome=unknown on the next tdoc run, so
  # a skipped run still produces a (degraded) event instead of vanishing.
  PENDING_DIR="$TEL_HOME/telemetry/pending"
  mkdir -p "$PENDING_DIR"
  TEL_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"skill":"tdoc","ts":"%s","session_id":"%s"}\n' \
    "$TEL_TS" "$TEL_SESSION_ID" > "$PENDING_DIR/.pending-$TEL_SESSION_ID"

  # Reap stale markers from prior skipped runs (any session but ours)
  for _PF in "$PENDING_DIR"/.pending-*; do
    [ -f "$_PF" ] || continue
    _PF_SID="$(basename "$_PF")"; _PF_SID="${_PF_SID#.pending-}"
    [ "$_PF_SID" = "$TEL_SESSION_ID" ] && continue
    _PDATA="$(cat "$_PF" 2>/dev/null || true)"
    rm -f "$_PF" 2>/dev/null || true
    [ -z "$_PDATA" ] && continue
    _P_SKILL="$(echo "$_PDATA" | grep -o '"skill":"[^"]*"' | head -1 | cut -d'"' -f4)"
    _P_SID="$(echo "$_PDATA" | grep -o '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4)"
    [ -z "$_P_SKILL" ] && continue
    if [ -x "__TDOC_DIR__/telemetry/bin/telemetry-log" ]; then
      "__TDOC_DIR__/telemetry/bin/telemetry-log" \
        --skill "$_P_SKILL" --outcome unknown \
        --step "reaped-incomplete-run" --session-id "$_P_SID" 2>/dev/null || true
    fi
  done
fi

# ─── Upgrade check (gstack-style lifecycle event) ───────────
# Check installed version against latest release. If stale, record
# upgrade_prompted event and tell the user (once per day, not nag).
# TDOC_DIR is substituted at install time by postinstall-telemetry.sh
# so this works no matter where tdoc is cloned.
TDOC_DIR="__TDOC_DIR__"

# Resolve installed version, trying multiple sources in order:
#   1. VERSION file (if maintained, like gstack)
#   2. git describe --tags (most recent reachable tag)
#   3. fallback "0.0.0" (skip the check)
INSTALLED_VERSION="$(cat "$TDOC_DIR/VERSION" 2>/dev/null)"
if [ -z "$INSTALLED_VERSION" ] && [ -d "$TDOC_DIR/.git" ]; then
  INSTALLED_VERSION="$(cd "$TDOC_DIR" && git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
fi
[ -z "$INSTALLED_VERSION" ] && INSTALLED_VERSION="0.0.0"

UPGRADE_CHECK_FLAG="$TEL_HOME/.upgrade-checked-$(date +%Y-%m-%d)"
if [ "$TEL_EFFECTIVE" != "off" ] && [ ! -f "$UPGRADE_CHECK_FLAG" ] && [ "$INSTALLED_VERSION" != "0.0.0" ]; then
  LATEST=$(curl -s --max-time 3 https://api.github.com/repos/serenakeyitan/tdoc/releases/latest 2>/dev/null | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 | sed 's/^v//')
  # Only fire upgrade prompt if installed is STRICTLY OLDER than latest.
  # Use sort -V (version sort): if installed sorts first, installed < latest.
  # If installed == latest or installed > latest (dev build), skip silently.
  if [ -n "$LATEST" ] && [ "$LATEST" != "$INSTALLED_VERSION" ]; then
    FIRST_VERSION=$(printf '%s\n%s\n' "$INSTALLED_VERSION" "$LATEST" | sort -V | head -1)
    if [ "$FIRST_VERSION" = "$INSTALLED_VERSION" ]; then
      "$TDOC_DIR/telemetry/bin/telemetry-log" \
        --skill tdoc \
        --event-type upgrade_prompted \
        --outcome unknown \
        --skill-version "$INSTALLED_VERSION" \
        --step "v$INSTALLED_VERSION→v$LATEST" \
        --session-id "$TEL_SESSION_ID" 2>/dev/null || true
      echo "TDOC_UPGRADE_AVAILABLE: $INSTALLED_VERSION → $LATEST  (cd $TDOC_DIR && git pull && bin/postinstall-telemetry.sh)"
    fi
  fi
  touch "$UPGRADE_CHECK_FLAG" 2>/dev/null || true
fi

echo "TEL_PROMPTED: $TEL_PROMPTED"
echo "TEL_EFFECTIVE: $TEL_EFFECTIVE"
echo "TEL_SESSION_ID: $TEL_SESSION_ID"
echo "TDOC_VERSION: $INSTALLED_VERSION"
```

### Instructions for the agent

**If `TEL_PROMPTED` is `no`** (first time the user runs tdoc with telemetry), ask
the user ONCE with this text and two options:

> tdoc can record when it runs, how it went (success/error/abandoned), how long it
> took, and a random ID for your machine, and send it to the tdoc maintainer's
> database. It does NOT record your tdoc content, your prompts, or anything else.
> Nothing is sent to Anthropic.
>
> A) **Help tdoc improve** — sends events (recommended)
> B) **Off** — nothing leaves your machine
>
> Change anytime: edit `~/.tdoc/.telemetry-mode`, or set `SKILL_TELEMETRY=off`.

**How to ask depends on your host:** if the `AskUserQuestion` tool is available
(Claude Code), use it with the two options above — this is the normal path and is
unchanged. If it is NOT available (e.g. Codex or any other host without that
tool), present the same text as plain prose and wait for the user's typed reply
(A/B). Either way, record their choice the same.

After they pick, record the choice:

```bash
echo "MODE_FROM_USER" > "$TEL_CONFIG_FILE"  # "on" or "off"
touch "$TEL_PROMPTED_FLAG"
TEL_EFFECTIVE="$(cat "$TEL_CONFIG_FILE")"
```

**If `TEL_PROMPTED` is `yes`**, do NOT ask again. Proceed silently.

---

## Final Step — Telemetry record (ALWAYS RUN LAST, no exceptions)

**This is the last required step of every tdoc run.** When the work is done —
success, error, or abandoned — you MUST record one telemetry event before telling
the user the task is complete.

**PLAN MODE EXCEPTION — ALWAYS RUN:** local writes + background sync; these always
run, even in plan mode.

"The doc is published" is NOT the end of the skill. The end of the skill is after
this telemetry event fires. A tdoc run that publishes a doc but logs no Final Step
event is an incomplete run — a regression.

```bash
TEL_HOME="$HOME/.tdoc"
TEL_SESSION_ID="${CLAUDE_SESSION_ID:-${TEL_SESSION_ID:-shell-$$-$(date +%s)}}"
END=$(date +%s)
START=$(cat "$TEL_HOME/sentinels/$TEL_SESSION_ID" 2>/dev/null || echo "$END")
DURATION=$(( END - START ))
rm -f "$TEL_HOME/sentinels/$TEL_SESSION_ID"

# Clear THIS session's pending marker — we're about to log the real
# event, so the self-healing reaper must not later treat it as orphaned.
rm -f "$TEL_HOME/telemetry/pending/.pending-$TEL_SESSION_ID" 2>/dev/null

TEL_EFFECTIVE="${SKILL_TELEMETRY:-$(cat "$TEL_HOME/.telemetry-mode" 2>/dev/null || echo on)}"
```

If `TEL_EFFECTIVE` is `off`, **stop here** — do not call telemetry-log.

Otherwise pick the block matching the outcome.

**For `--step`, pick the tdoc subcommand**: `new`, `edit`, `publish`, `list`,
`pull`, `unpublish`, `onboard`, `doctor`, `update`. If the user invoked multiple
in one session, use the last one. If it was an ad-hoc mention (not a /tdoc
command), use `chat` or `freeform`.

**On success**:

```bash
"__TDOC_DIR__/telemetry/bin/telemetry-log" \
  --skill tdoc \
  --outcome success \
  --duration "$DURATION" \
  --step "<subcommand: new|edit|publish|list|pull|unpublish|onboard|doctor|update|chat>" \
  --skill-version "$INSTALLED_VERSION" \
  --session-id "$TEL_SESSION_ID"
```

**On error**:

```bash
"__TDOC_DIR__/telemetry/bin/telemetry-log" \
  --skill tdoc \
  --outcome error \
  --duration "$DURATION" \
  --error-class "<short tag, e.g. 'publish_timeout' / 'auth_failed' / 'malformed_input'>" \
  --error-message "<full debug context, ≤400 chars>" \
  --step "<which subcommand was running and what phase failed>" \
  --skill-version "$INSTALLED_VERSION" \
  --session-id "$TEL_SESSION_ID"
```

**On abandoned** (user asked to stop):

```bash
"__TDOC_DIR__/telemetry/bin/telemetry-log" \
  --skill tdoc \
  --outcome abandoned \
  --duration "$DURATION" \
  --step "<subcommand + phase you were on>" \
  --skill-version "$INSTALLED_VERSION" \
  --session-id "$TEL_SESSION_ID"
```

The script is fire-and-forget. It returns instantly and syncs to Supabase in the
background.

### Three opt-out paths

- **First run**: pick "Off" in the consent prompt above
- **Persistent**: `echo off > ~/.tdoc/.telemetry-mode`
- **Ephemeral**: `export SKILL_TELEMETRY=off`

See `telemetry/PRIVACY.md` for the full list of recorded fields.
