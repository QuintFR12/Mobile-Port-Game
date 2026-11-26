#!/bin/zsh
set -euo pipefail

ROOT="/Users/adanevanarkel/Desktop/Quint/GitHub/Mobile-Port-Game"
TEST_DIR="$ROOT/Test"
LIVE_DIR="$ROOT/Live"

if [[ -n "$(git -C "$TEST_DIR" status --porcelain)" ]]; then
  echo "Test bevat wijzigingen. Commit of verwijder ze eerst."
  exit 1
fi

if [[ -n "$(git -C "$LIVE_DIR" status --porcelain)" ]]; then
  echo "Live bevat wijzigingen. Commit of verwijder ze eerst."
  exit 1
fi

echo "Testen in Test..."
swift test --package-path "$TEST_DIR"

echo "Testbranch naar Live promoten..."
git -C "$TEST_DIR" fetch origin test/main
git -C "$TEST_DIR" pull --ff-only origin test/main
git -C "$LIVE_DIR" merge --ff-only test/main

echo "Live is bijgewerkt naar de getestte test/main-versie."
