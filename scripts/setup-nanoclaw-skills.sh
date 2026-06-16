#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
SOURCE_SKILLS="/home/agent/nanoclaw/.claude/skills"
TARGET_SKILLS="$PROJECT_ROOT/.claude/skills"

if [ ! -d "$SOURCE_SKILLS" ]; then
  echo "NanoClaw skills not found at $SOURCE_SKILLS"
  exit 1
fi

mkdir -p "$TARGET_SKILLS"
cp -r "$SOURCE_SKILLS"/* "$TARGET_SKILLS"/

echo "NanoClaw skills installed into $TARGET_SKILLS"
echo "Now run:"
echo "  claude"
echo "  /reload-skills"
echo "  /setup"
