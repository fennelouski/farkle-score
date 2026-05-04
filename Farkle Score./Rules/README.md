# In-app rule references

Markdown rule summaries live under `Resources/` and are listed in `Resources/rules_index.json`. The synced Xcode group picks them up automatically—no need to edit `project.pbxproj`.

### Adding a new rules file

1. Add `MyRules.md` under `Farkle Score./Rules/Resources/`.
2. Append one object to `rules_index.json` → `rulesets` (fields: `id`, `filename`, `title`, `subtitle`, `family` = `farkle` or `zilch`, optional `sourceURL`).
3. Build or run tests; the new ruleset appears in **Rules** in the app.

Optional: entries whose `filename` is missing from the bundle are skipped (e.g. a future `FARKLE_RULES_PLAYMONSTER.md` can stay in the index until the file exists).
