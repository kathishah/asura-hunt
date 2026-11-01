#!/usr/bin/env bash
# Publishes the game to Roblox: runs the "Publish to Roblox" GitHub workflow for `main`, waits for
# it, and shows what Roblox answered.
#
#   tools/publish.sh            publish (goes live)
#   tools/publish.sh --saved    store a version without publishing it
#
# Roblox refuses an upload while Studio has the place open (HTTP 409 "server is busy"), so if Studio
# is running this asks before closing it, waits, and checks it is really gone.
#
# What it publishes is `main` on GitHub, not your working copy: merge first. Setup (API key and ids)
# is in docs/PUBLISHING.md. macOS only.
#
# Testing: PUBLISH_DRY_RUN=1 skips the GitHub step; STUDIO_QUIT_WAIT=<seconds> shortens the wait.

set -euo pipefail
cd "$(dirname "$0")/.." # the project root, wherever it is run from

STUDIO_PROCESS="RobloxStudio"
STUDIO_BUNDLE_ID="com.Roblox.RobloxStudio"
QUIT_WAIT="${STUDIO_QUIT_WAIT:-30}"
WORKFLOW="publish.yml"

version_type="Published"
case "${1:-}" in
	"") ;;
	--saved) version_type="Saved" ;;
	-h | --help)
		sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
		exit 0
		;;
	*)
		echo "Unknown option: $1 (try --help)" >&2
		exit 2
		;;
esac

die() {
	echo "Error: $*" >&2
	exit 1
}

ask() { # ask "question"  -> succeeds only on y or yes
	local answer
	read -r -p "$1 [y/N] " answer
	case "${answer}" in y | Y | yes | YES | Yes) return 0 ;; *) return 1 ;; esac
}

studio_running() { pgrep -x "${STUDIO_PROCESS}" > /dev/null; }

wait_for_studio_exit() { # wait_for_studio_exit <seconds>
	local waited=0
	while studio_running && [ "${waited}" -lt "$1" ]; do
		sleep 1
		waited=$((waited + 1))
		printf '.'
	done
	echo
	! studio_running
}

[ "$(uname)" = "Darwin" ] || die "this script is for macOS"
[ -t 0 ] || die "run it in a terminal; it asks questions"
command -v gh > /dev/null || die "the GitHub CLI (gh) is not installed"
gh auth status > /dev/null 2>&1 || die "gh is not logged in: run 'gh auth login'"

# --- What will be published ---------------------------------------------------------------------
git fetch -q origin main || die "could not reach GitHub"
remote_main="$(git rev-parse origin/main)"
echo "Will publish origin/main as ${version_type}:"
echo "  $(git log -1 --format='%h %s (%cr)' origin/main)"
if [ "$(git branch --show-current)" != "main" ] || [ "$(git rev-parse HEAD)" != "${remote_main}" ]; then
	echo "Note: your working copy is not at origin/main. The workflow publishes origin/main, so merge"
	echo "      and 'git pull' first if you expected something else to go out."
fi
echo

# --- Studio -------------------------------------------------------------------------------------
if studio_running; then
	echo "Roblox Studio is running. Roblox rejects an upload while Studio has the place open."
	echo "Closing it is safe for the code (it is all in git), but save anything you want to keep"
	echo "first. Studio may ask whether to save: choose Save."
	ask "Quit Roblox Studio now?" || die "cancelled; Studio was left running"

	# Politely first, so Studio can offer to save.
	osascript -e "tell application id \"${STUDIO_BUNDLE_ID}\" to quit" > /dev/null 2>&1 || true
	printf 'Waiting up to %ss for Studio to quit' "${QUIT_WAIT}"
	if ! wait_for_studio_exit "${QUIT_WAIT}"; then
		echo "Studio is still running (it may be waiting for you to answer a save prompt)."
		ask "Force it to stop? Unsaved changes in Studio would be lost." ||
			die "Studio is still running; not publishing"
		pkill -x "${STUDIO_PROCESS}" || true
		printf 'Waiting up to 15s for Studio to stop'
		wait_for_studio_exit 15 || die "Studio did not stop; close it by hand and run this again"
	fi
	studio_running && die "Studio is still running"
	echo "Studio is closed."
	echo
else
	echo "Roblox Studio is not running."
	echo
fi

# --- Publish ------------------------------------------------------------------------------------
ask "Publish now?" || die "cancelled"

if [ -n "${PUBLISH_DRY_RUN:-}" ]; then
	echo "Dry run: would run: gh workflow run ${WORKFLOW} --ref main -f version_type=${version_type}"
	exit 0
fi

previous_run="$(gh run list --workflow "${WORKFLOW}" --limit 1 --json databaseId --jq '.[0].databaseId // 0')"
gh workflow run "${WORKFLOW}" --ref main -f version_type="${version_type}"

run_id=""
for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
	sleep 5
	latest="$(gh run list --workflow "${WORKFLOW}" --limit 1 --json databaseId --jq '.[0].databaseId // 0')"
	if [ "${latest}" != "${previous_run}" ]; then
		run_id="${latest}"
		break
	fi
done
[ -n "${run_id}" ] || die "the run did not show up; look in the Actions tab on GitHub"

echo "Started: $(gh run view "${run_id}" --json url --jq .url)"
if gh run watch "${run_id}" --exit-status --interval 10 > /dev/null 2>&1; then
	result="succeeded"
else
	result="FAILED"
fi

reply="$(gh run view "${run_id}" --log 2>/dev/null | grep -Eo 'Roblox answered HTTP [0-9]{3}: .*' | head -1 || true)"
echo
echo "Publish ${result}."
[ -n "${reply}" ] && echo "${reply}"

if [ "${result}" = "succeeded" ]; then
	echo
	echo "Next: join the live game from the Roblox site or app and check it. When you reopen Studio,"
	echo "accept the newer version of the place if it offers one, then reconnect Rojo."
else
	echo
	echo "Look at the log: gh run view ${run_id} --log-failed"
	echo "If the reply says 'server is busy' (409), make sure Studio is closed, wait a minute and retry."
	exit 1
fi
