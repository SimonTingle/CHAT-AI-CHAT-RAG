#!/bin/bash
set -e

git add README.md CONTRIBUTING.md LICENSE docs/ *.txt
git commit -m "docs: add/update project documentation" || echo "No changes to commit"

git checkout main
git pull origin main
git push origin main

for branch in $(git branch --format="%(refname:short)" | grep -v "main"); do
  git checkout "$branch"
  git pull origin "$branch"
  git merge main --no-edit || true
  git push origin "$branch"
done

git checkout main
