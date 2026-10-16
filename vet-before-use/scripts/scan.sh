#!/usr/bin/env bash
# First-pass scan of a directory or file for risky patterns. Read-only: never executes the target.
# Usage: scan.sh <path>
set -u
target="${1:-}"
if [ -z "$target" ] || [ ! -e "$target" ]; then
  echo "usage: scan.sh <existing file or directory>" >&2
  exit 2
fi

echo "== Files =="
find "$target" -type f -printf '%s\t%p\n' 2>/dev/null | sort -k2 | head -200
echo
echo "== File types (non-text flagged) =="
find "$target" -type f -print0 | xargs -0 file 2>/dev/null | grep -viE 'text|json|empty|xml|utf-8' || echo "none"
echo
echo "== Executable bits / symlinks / hidden =="
find "$target" \( -perm -u+x -o -type l -o -name '.*' \) -not -path "$target" -print 2>/dev/null || true
echo

scan() {
  label="$1"; pattern="$2"
  hits=$(grep -rnIE --binary-files=without-match "$pattern" "$target" 2>/dev/null | cut -c1-200 | head -40)
  echo "== $label =="
  if [ -n "$hits" ]; then echo "$hits"; else echo "none"; fi
  echo
}

scan "Network" 'curl |wget |fetch\(|https?://|nc -|/dev/tcp|socket|webhook|ngrok|pastebin|bit\.ly|requests\.|axios'
scan "Pipe to shell" '\|\s*(sudo\s+)?(ba|z)?sh\b|\|\s*python|\|\s*node'
scan "Credentials / secrets" '\.ssh|id_rsa|\.aws|\.env\b|api[_-]?key|secret|token|passw(or)?d|credentials|keychain|\.netrc|\.git-credentials|HTTPS_PROXY'
scan "Obfuscation / dynamic exec" 'eval\(|exec\(|base64|atob\(|btoa\(|Function\(|\\x[0-9a-fA-F]{2}|\\u[0-9a-fA-F]{4}|fromCharCode|__import__|importlib|pickle\.loads|subprocess|os\.system|child_process'
scan "Persistence / system changes" 'crontab|/etc/|systemd|\.bashrc|\.profile|\.zshrc|authorized_keys|chmod \+x|chmod 7|sudo |npm (i|install) -g|pip install|postinstall|preinstall|git config|\.git/hooks'
scan "Destructive" 'rm -rf|mkfs|dd if=|:\(\)\{|shred|git push (-f|--force)|git reset --hard|truncate -s 0'
scan "Prompt-injection phrases" 'ignore (all |any )?(previous|prior|above)|disregard|do not (tell|mention|reveal)|without (telling|asking)|hide (this|it) from|you must not (tell|inform)|system prompt|override (the )?(rules|instructions)|skip (the )?(check|review|scan)|run this first'

echo "== Invisible / bidi Unicode characters =="
if grep -rnIP '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{FEFF}]' "$target" 2>/dev/null | head -20 | grep -q .; then
  grep -rnIP '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{FEFF}]' "$target" 2>/dev/null | cut -c1-120 | head -20
else
  echo "none"
fi
echo
echo "Scan finished. Hits are leads, not verdicts: read the files in full before judging."
