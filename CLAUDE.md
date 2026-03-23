# CLAUDE.md - Superthread

## Commands

```bash
bundle exec rspec                              # Run tests
bundle exec rspec spec/path_spec.rb:42         # Single test by line
bundle exec standardrb                         # Check code style
bundle exec standardrb --fix                   # Auto-fix style issues
bundle exec yard-lint lib/                     # Check YARD documentation
bundle exec bin/suth cards get CARD_ID         # Run CLI locally
bundle exec bin/suth cards get CARD_ID --json  # Raw JSON (useful for debugging API responses)
```

**IMPORTANT:** After making code changes to Ruby files:
1. Run `bundle exec standardrb --fix` to ensure code follows StandardRB conventions
2. Run `bundle exec yard-lint lib/` to validate YARD documentation tags and ordering

Both checks are enforced by Lefthook pre-commit hooks.

## Resource Pattern

API resources inherit from `Resources::Base`. Use these helpers:

| Method | Purpose |
|--------|---------|
| `safe_id(name, value)` | Validates IDs, prevents path traversal |
| `compact_params(**args)` | Filters nil values from params hash |
| `get_object`, `post_object` | HTTP verbs returning typed models |
| `get_collection`, `post_collection` | HTTP verbs returning collections |
| `success_response` | Returns `{ success: true }` for delete operations |

## CLI Output

Use these methods in CLI commands (all respect `--json` flag):

```ruby
output_item card, fields: %i[id title status]    # Single item as key-value pairs
output_list cards, columns: %i[id title status]  # Collection as table
output_success "Card deleted"                    # Success message
```

## Adding a New Resource

1. Create model in `lib/superthread/models/`
2. Create resource in `lib/superthread/resources/`
3. Add to client in `lib/superthread/client.rb`
4. Create CLI commands in `lib/superthread/cli/`
5. Register subcommand in `lib/superthread/cli/main.rb`
6. Add specs
7. Update the CLI skill in `skills/superthread/SKILL.md`

## CLI Skill

The file `skills/superthread/SKILL.md` is a Claude Code skill that teaches agents how to use the `suth` CLI. It is the canonical reference for all CLI commands, options, and usage patterns.

**IMPORTANT:** When adding, removing, or changing CLI commands, options, or behavior, update the skill file to match. This keeps agents in sync with the CLI without needing to run `--help` for every command.

## Key Design Decisions

1. **Shale Models** - Type-safe serialization with declarative attributes
2. **Factory Error Pattern** - `ApiError.from_response` creates specific error types from status/body
3. **gh-style CLI** - Human-readable output by default, `--json` for scripting
4. **Gum/Glamour UI** - Charmbracelet tools for styled terminal output
