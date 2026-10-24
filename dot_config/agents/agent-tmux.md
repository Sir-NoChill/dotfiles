# Agent-aware tmux status dots

Per-agent status indicator (working / needs-you / done) in plain tmux, driven by each
agent's own lifecycle hooks — no daemon, no JS runtime. An agent hook pushes a status
word to the tmux window it runs in via the `@agent` user option; the status line paints
a colored dot from it.

Three moving parts:

1. The relay script `~/.local/bin/agent-tmux` (`dot_local/bin/executable_agent-tmux`).
   Takes the status word as its first argument and writes it onto the calling pane's
   window as `@agent`. Always exits 0, so a hook can never stall or fail a turn, and
   no-ops when not under tmux (`$TMUX_PANE` empty).
2. Each agent's hook config, mapping lifecycle events to `agent-tmux <word>`.
3. `~/.tmux.conf.local` (`dot_tmux.conf.local`), which reads `@agent` and renders the dot.

## Event → status contract (stable)

The words must stay exact — `dot_tmux.conf.local` matches them literally.

| Lifecycle event   | Status word | Glyph / colour | Fires when                       |
| ----------------- | ----------- | -------------- | -------------------------------- |
| `SessionStart`    | `idle`      | `·` dim        | Agent launches or resumes        |
| `UserPromptSubmit`| `working`   | `▶` yellow     | You submit a prompt              |
| `PreToolUse`      | `working`   | `▶` yellow     | Agent is about to run a tool     |
| `Notification`    | `needs`     | `●` red        | Agent asks for permission/input  |
| `Stop`            | `done`      | `●` green      | The turn finishes                |

`PostToolUse` is intentionally unused — `PreToolUse` already set `working`.

Use an absolute path (`$HOME/.local/bin/agent-tmux`) in hooks, since `~` is not reliably
expanded in every agent's hook runner.

## Claude Code — wired

Configured in `~/.claude/settings.json` (tracked here as `private_dot_claude/settings.json`).
These are the exact events, mapped to the words above. If other hooks are added later,
merge arrays per event rather than overwriting.

## Codex / Pi / OpenCode — stubs for later

The status mapping is identical; only the configuration surface differs, and these
schemas vary by version — confirm against the installed tool before wiring.

- **Codex** — exposes the same event names (`SessionStart`, `UserPromptSubmit`,
  `PreToolUse`, `Stop`, …) and asks you to trust command hooks once via its `/hooks`
  command. Wire the same four events to `agent-tmux`.
- **Pi** — surfaces lifecycle through an extension under
  `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/extensions/`, not a settings file. A small
  extension must call `agent-tmux` (or run `tmux set` directly). The one provider that
  cannot be done with config alone.
- **OpenCode** — has no built-in command-hook settings equivalent; needs a plugin to
  emit the same four transitions. Optional.

Any tool that can run a command at these moments plugs in with no change to the script
or the tmux config: a future helper can set the same `@agent` option.

## Verify (inside a tmux session)

1. `~/.local/bin/agent-tmux working` then `tmux show -w @agent` prints `working`.
2. `tmux set -w @agent needs` → red dot; `done` → green; `idle` → dim.
3. Start an agent in a tmux window and submit a prompt: yellow (working) → red on a
   permission prompt (needs) → green when the turn ends (done).
4. With `$TMUX_PANE` unset the relay no-ops and the agent behaves normally.
5. `echo '{}' | ~/.local/bin/agent-tmux working; echo $?` prints `0` immediately.
