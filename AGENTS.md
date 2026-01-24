# AGENTS.md - Superthread Ruby Gem

Guidelines for AI coding agents working in this repository.

## Project Overview

Ruby gem providing a library and CLI for the Superthread project management API.
- **Language:** Ruby >= 3.2.0
- **CLI Framework:** Thor
- **HTTP Client:** Faraday
- **Models:** Shale (type-safe serialization)
- **Style:** StandardRB (RuboCop-based)

## Commands

```bash
bundle exec rspec                              # Run tests
bundle exec rspec spec/path_spec.rb:42         # Single test by line
bundle exec rubocop -a                         # Lint and auto-fix
bundle exec bin/suth cards get CARD_ID         # Run CLI locally
```

## Resource Pattern

API resources inherit from `Resources::Base`. Use these helpers:

| Method | Purpose |
|--------|---------|
| `safe_id(name, value)` | Validates IDs, prevents path traversal |
| `compact_params(**args)` | Filters nil values from params hash |
| `get_object`, `post_object` | HTTP verbs returning typed models |
| `get_collection`, `post_collection` | HTTP verbs returning collections |
| `success_response` | Returns `{ success: true }` for delete operations |

Example:
```ruby
def find(workspace_id, card_id)
  ws = safe_id("workspace_id", workspace_id)
  card = safe_id("card_id", card_id)
  get_object("/#{ws}/cards/#{card}", object_class: Models::Card, unwrap_key: :card)
end
```

## Error Hierarchy

```
Superthread::Error
  ConfigurationError              # Config issues (client-side)
  PathValidationError             # ID validation (client-side)
  ApiError                        # HTTP errors (base)
    ClientError                   # 4xx errors
      AuthenticationError (401)
      ForbiddenError (403)
      NotFoundError (404)
      ValidationError (400, 422)
      RateLimitError (429)
    ServerError                   # 5xx errors
```

## CLI Output

Use these methods in CLI commands (all respect `--json` flag):

```ruby
output_item card, fields: %i[id title status]    # Single item as key-value pairs
output_list cards, columns: %i[id title status]  # Collection as table
output_success "Card deleted"                    # Success message
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPERTHREAD_API_KEY` | API authentication key |
| `SUPERTHREAD_WORKSPACE_ID` | Default workspace ID |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: https://api.superthread.com/v1) |

## Adding a New Resource

1. Create model in `lib/superthread/models/`
2. Create resource in `lib/superthread/resources/`
3. Add to client in `lib/superthread/client.rb`
4. Create CLI commands in `lib/superthread/cli/`
5. Register subcommand in `lib/superthread/cli/main.rb`
6. Add specs

## Key Design Decisions

1. **Shale Models** - Type-safe serialization with declarative attributes
2. **Factory Error Pattern** - `ApiError.from_response` creates specific error types from status/body
3. **gh-style CLI** - Human-readable output by default, `--json` for scripting
4. **Gum/Glamour UI** - Charmbracelet tools for styled terminal output
