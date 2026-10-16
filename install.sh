#!/bin/bash
# krnr Browser – Installation/Aktualisierung auf macOS (Apple Silicon).
#   curl -fsSL https://raw.githubusercontent.com/akrnr/krnr-browser/main/install.sh | bash
# Laedt die aktuelle Version per curl (ohne Quarantaene-Markierung), prueft die
# SHA-256-Pruefsumme und die Code-Signatur und installiert nach /Applications.
# Danach aktualisiert sich der Browser selbst (Sparkle, EdDSA-signierte Updates).
set -euo pipefail
REPO="akrnr/krnr-browser"
RAW="https://raw.githubusercontent.com/$REPO/main/mac"
APP="krnr Browser.app"
DEST="/Applications/$APP"

[ "$(uname -s)" = Darwin ] || { echo "Nur fuer macOS." >&2; exit 1; }
[ "$(uname -m)" = arm64 ] || { echo "Nur fuer Apple Silicon (arm64)." >&2; exit 1; }

n="$(curl -fsSL "$RAW/latest")"
sum="$(curl -fsSL "$RAW/latest.sha256")"
url="https://github.com/$REPO/releases/download/v$n/krnr-Browser-$n.dmg"
tmp="$(mktemp -d)"; trap 'hdiutil detach -quiet "$tmp/mnt" 2>/dev/null || true; rm -rf "$tmp"' EXIT

echo "Lade krnr Browser Build $n ..."
curl -fL --progress-bar -o "$tmp/krnr.dmg" "$url"
echo "$sum  $tmp/krnr.dmg" | shasum -a 256 -c - >/dev/null || { echo "Pruefsumme stimmt nicht – Abbruch." >&2; exit 1; }

hdiutil attach -quiet -nobrowse -readonly -mountpoint "$tmp/mnt" "$tmp/krnr.dmg"
codesign --verify --deep --strict "$tmp/mnt/$APP" || { echo "Signatur ungueltig – Abbruch." >&2; exit 1; }

if pgrep -xq "krnr Browser"; then
  echo "Bitte krnr Browser zuerst beenden und das Skript erneut starten." >&2; exit 1
fi
if [ -d "$DEST" ]; then rm -rf "$DEST"; fi
ditto "$tmp/mnt/$APP" "$DEST"
echo "Installiert: $DEST (Build $n). Updates kommen ab jetzt automatisch."
