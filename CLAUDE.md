@AGENTS.md

## Claude Code notes

- The rules in AGENTS.md are the source of truth. Edit them there so every tool stays in sync.
- Start a session by reading `docs/GAME_DESIGN.md` to see which roadmap milestone is current.
- After code changes, finish with a short "please playtest" checklist for the human.
- When unsure about a Roblox API, say so and point at the official docs rather than guessing.
- You may generate map geometry as code; follow "Building the map as code" in AGENTS.md. Put the builder in `tools/`, then run it in Studio (command bar, edit mode) and look at the result before saying it is done. The "Dangerous Command" dialog on a builder's delete needs full-screen control to click Continue; ask for it for that one step only.
- The human's open Studio place holds the real map and may contain hand edits. Ask before re-running a builder over it.
