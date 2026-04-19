#!/bin/bash
# SessionStart hook: inject all skill definitions into context
# Fires on new sessions, resumes, /clear, and after compaction

SKILLS_DIR="$HOME/.claude/skills"

if [ ! -d "$SKILLS_DIR" ]; then
  exit 0
fi

echo "=== LOADED SKILLS — USE THESE PROACTIVELY ==="
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    echo "--- SKILL: $skill_name ---"
    cat "$skill_file"
    echo ""
  fi
done

echo "=== Remember: check if a skill matches your current task before responding ==="
