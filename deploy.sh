#!/bin/bash
# Commit + push → GitHub Actions compila y despliega por FTP
set -euo pipefail

cd "$(dirname "$0")"

mensaje=$(osascript -e 'tell application "System Events" to display dialog "Describe los cambios:" default answer ""' -e 'text returned of result')

if [ -z "$mensaje" ]; then
  echo "❌ Mensaje vacío, cancelado."
  exit 1
fi

git add -A

if git diff --cached --quiet; then
  echo "❌ No hay cambios para commitear."
  exit 1
fi

commit_msg_file=$(mktemp)
trap 'rm -f "$commit_msg_file"' EXIT
printf "%s\n" "$mensaje" > "$commit_msg_file"

git commit -F "$commit_msg_file"
git push

echo ""
echo "✅ Push enviado a GitHub."
echo "🚀 GitHub Actions compilará y subirá por FTP (Actions → Build and deploy to FTP)."
