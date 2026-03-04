---
name: release
description: Guide through releasing a new version of superthread. Use when cutting a release, publishing a new version, or bumping the version.
---

# Release superthread

The release process is: bump version → commit → `rake release` → GitHub Actions builds the gem, creates a GitHub Release, and updates the Homebrew formula.

---

## Step 1 — Review unreleased changes

Run `git log v$(ruby -r ./lib/superthread/version -e 'puts Superthread::VERSION')..HEAD --oneline` to see what changed since the last release.

Read `lib/superthread/version.rb` for the current version.

Summarize the changes for the user and recommend a semver bump:

| Bump | When |
|------|------|
| **major** | Breaking changes to the public API |
| **minor** | New features, backward compatible |
| **patch** | Bug fixes, docs, internal changes only |

## Step 2 — Draft release notes

Write concise, user-facing release notes grouped under headings as appropriate:

- `### Added` — new features or commands
- `### Changed` — behavior changes
- `### Fixed` — bug fixes
- `### Removed` — removed features or commands

These will become the GitHub Release body. Keep it brief and practical.

Show the draft to the user for confirmation before proceeding.

## Step 3 — Bump version

Use the bump gem to update `lib/superthread/version.rb`:

```bash
bundle exec bump patch   # or minor, major
```

This modifies the version file but does NOT commit or tag.

## Step 4 — Commit

Stage and commit the version bump:

```bash
git add lib/superthread/version.rb
git commit -m "release: v<VERSION>"
```

## Step 5 — Run `rake release`

```bash
bundle exec rake release
```

This will:
1. Verify the tag doesn't already exist
2. Verify no uncommitted changes to version.rb
3. Show what will happen and ask for confirmation
4. Create an annotated git tag (`v<VERSION>`)
5. Push the tag to origin
6. GitHub Actions then: runs tests, builds the gem, creates a GitHub Release, and updates the Homebrew formula

## Step 6 — Add release notes

After GitHub Actions creates the release, update it with the drafted notes:

```bash
gh release edit v<VERSION> --notes "$(cat <<'EOF'
<release notes here>
EOF
)"
```

---

## Troubleshooting

- **Tag already exists**: The version was already released. Bump to the next version.
- **Uncommitted changes**: Commit everything before running `rake release`.
- **GitHub Actions fails**: Check https://github.com/steveclarke/superthread/actions for details.
- **Homebrew tap not updated**: Verify the `HOMEBREW_TAP_TOKEN` secret is configured in GitHub repo settings.
