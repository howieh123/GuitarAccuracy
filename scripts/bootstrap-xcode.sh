#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Installing XcodeGen via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install Homebrew first: https://brew.sh" >&2
    exit 1
  fi
  brew install xcodegen
fi

xcodegen --version | cat

pushd macos >/dev/null
xcodegen generate --use-cache
popd >/dev/null

echo "Attempting CLI build..."
xcodebuild -project macos/GuitarAccuracy.xcodeproj -scheme GuitarAccuracy -configuration Debug -destination 'platform=macOS' build | cat

echo "Done. You can open the project in Xcode: open macos/GuitarAccuracy.xcodeproj"
