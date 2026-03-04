---
name: release
description: Guide through releasing a new version of superthread. Use when cutting a release, publishing a new version, or bumping the version.
---

# Release superthread

Bump version → commit → `rake release` → GitHub Actions handles the rest (gem build, GitHub Release, Homebrew formula).

## Workflow

### 1. Review unreleased changes

```bash
ruby -r ./lib/superthread/version -e 'puts Superthread::VERSION'
git log v<CURRENT_VERSION>..HEAD --oneline
```

Summarize changes and recommend a bump: **major** (breaking), **minor** (new features), or **patch** (fixes/docs).

### 2. Draft release notes

Write concise, user-facing notes. Group under `### Added`, `### Changed`, `### Fixed`, `### Removed` as appropriate. Show the draft to the user for confirmation.

### 3. Bump, commit, release

```bash
bundle exec bump patch          # or minor, major — updates version.rb and commits
bundle exec rake release        # creates tag, pushes, triggers GitHub Actions
```

> The `bump` command runs `bundle install` automatically to sync `Gemfile.lock`, then commits both files. Do NOT edit `version.rb` by hand — the lockfile will be out of sync and CI will fail in frozen mode.

### 4. Add release notes

After GitHub Actions creates the release (check progress at the Actions URL shown in output):

```bash
gh release edit v<VERSION> --notes "$(cat <<'EOF'
<release notes from step 2>
EOF
)"
```

## If something goes wrong

- **Tag exists** → version already released, bump again
- **Uncommitted changes** → commit everything first
- **Actions fail** → check https://github.com/steveclarke/superthread/actions
- **Homebrew not updated** → verify `HOMEBREW_TAP_TOKEN` secret in repo settings
