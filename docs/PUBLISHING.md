# Publishing the game with the API

The **Publish to Roblox** workflow (`.github/workflows/publish.yml`) builds the place with Rojo and uploads it to Roblox through the Open Cloud place-publishing API. It runs by hand, from the `main` branch only. The same upload can be done from Studio with File > Publish; whichever ran last wins.

## What an upload does

An upload **replaces the whole live place** with the built file. So everything the game needs must come from git:

- the scripts (`src/`),
- the map (`map/*.rbxm`),
- the place settings (lighting, sky, streaming, respawn time and so on), which live in `default.project.json`.

`tools/check-place.luau` stops the workflow if the build has lost the map, a script folder, the sky or key settings. CI runs it on every pull request too.

Not touched by an upload: experience-level settings in Creator Hub (name, privacy, max players, API access, monetisation) and players' saved data.

## One-time setup

1. **Find the ids.** In Studio's command bar run `print(game.GameId, game.PlaceId)`. The first number is the **universe id**, the second the **place id**. They are not secret. (They are also in Creator Hub: Creations, then your experience.)
2. **Create an API key** at create.roblox.com, **Open Cloud > API Keys > Create API Key**:
   - Access Permissions: add **universe-places**, choose **this experience only**, and tick **Write**.
   - Set an expiry (you will have to make a new key then).
   - Copy the key when it is shown. It cannot be shown again. **Never paste it into chat, a file or a commit.**
3. **Give GitHub the key and ids.** In a terminal in this folder (the first command asks you to paste the key, so it never lands in your shell history):
   ```bash
   gh secret set ROBLOX_API_KEY
   gh variable set ROBLOX_UNIVERSE_ID --body "<universe id>"
   gh variable set ROBLOX_PLACE_ID --body "<place id>"
   ```
   Or in the repository on GitHub: Settings > Secrets and variables > Actions.

## Publishing

Merge to `main` first: the workflow publishes `main` on GitHub, not your working copy. Then, in the project folder:

```bash
./publish.sh
```

It shows what will go out, and if Roblox Studio is running it asks before quitting it (politely first, so Studio can offer to save; force-stopping is a second question), waits, and checks Studio is gone. Then it starts the workflow, waits for it, and prints what Roblox answered. `./publish.sh --saved` stores a version without publishing it.

**Close Studio first.** With Studio open on the place (Team Create on), Roblox answered every upload with HTTP 409, "Save failed. Server is busy and unable to process your upload request." The same upload worked as soon as Studio was closed. The docs do not mention this, so it is an observation, not a documented rule.

Without the script: GitHub, then **Actions > Publish to Roblox > Run workflow**, branch `main`, or `gh workflow run publish.yml --ref main -f version_type=Published`. The job runs the normal checks, builds, runs the place check, uploads, and prints the version number Roblox returns.

`version_type` is `Published` (goes live) or `Saved`. Both returned HTTP 200 in testing. The docs only show `Published`, and in our first test both calls returned the same version number (11), so do not assume a `Saved` upload leaves the live game untouched until you have seen it do so.

After a publish, join the live game from the Roblox site or app and check it. When you reopen Studio it may offer a newer version of the place: accept it, then reconnect Rojo.

If the key stops working (HTTP 401 or 403), it expired or was unused for 60 days: create a new one in Creator Hub and run `gh secret set ROBLOX_API_KEY` again.

## Keeping Studio and git in step

- A map or setting change made by hand in Studio is not published unless it is in git: File > Download a Copy, `lune run tools/extract-map <file.rbxl>` for the map, or edit `default.project.json` for a setting. See AGENTS.md.
- To see whether Studio and the built place still agree, compare a fresh Download a Copy with `rojo build` (ask Claude; the check used to set this up is described in the pull request).

## Limits (from the API docs)

The API does not update `EditableImage`, `EditableMesh`, `PartOperation` (unions), `SurfaceAppearance` or `BaseWrap` instances. The map uses plain parts, so this does not affect it today. If you add unions or meshes later, publish from Studio.
