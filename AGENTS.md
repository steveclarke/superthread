# AGENTS.md - Superthread Ruby Gem

Guidelines for AI coding agents working in this repository.

## Project Overview

Ruby gem providing a library and CLI for the Superthread project management API.
- **Language:** Ruby >= 3.1.0
- **CLI Framework:** Thor
- **HTTP Client:** Faraday
- **Autoloading:** Zeitwerk
- **Style:** StandardRB (RuboCop-based)
- **Design Inspiration:** Stripe Ruby gem (rich objects), Octokit (error handling), gh CLI (output formatting)

## Build/Test/Lint Commands

```bash
# Install dependencies
bundle install

# Run full test suite
bundle exec rspec

# Run a single test file
bundle exec rspec spec/superthread/client_spec.rb

# Run a single test by line number
bundle exec rspec spec/superthread/client_spec.rb:42

# Run tests matching a pattern
bundle exec rspec --example "creates a card"

# Run linter (StandardRB)
bundle exec rubocop

# Auto-fix linting issues
bundle exec rubocop -a

# Run both tests and linter (default rake task)
bundle exec rake

# Run CLI locally during development
bundle exec bin/st version
bundle exec bin/st cards get CARD_ID
bundle exec bin/st cards assigned USER_ID
```

## Directory Structure

```
lib/
  superthread.rb           # Entry point, Zeitwerk loader setup
  superthread/
    version.rb             # VERSION constant
    error.rb               # Error class hierarchy with factory method
    client.rb              # Main API client (composition root)
    configuration.rb       # Config file and env var handling
    connection.rb          # Faraday HTTP wrapper
    object.rb              # Base class for rich response objects
    objects/               # Typed response object classes
      card.rb              # Card, Member, LinkedCard
      board.rb             # Board, List
      user.rb              # User
      project.rb           # Project (epic/roadmap item)
      space.rb             # Space
      sprint.rb            # Sprint
      comment.rb           # Comment
      page.rb              # Page (document)
      note.rb              # Note
      tag.rb               # Tag
      checklist.rb         # Checklist, ChecklistItem
      collection.rb        # Collection wrapper for list responses
    cli/                   # Thor CLI commands
      base.rb              # Shared options, client access, output helpers
      main.rb              # Command routing
      formatter.rb         # gh-style output formatting (tables, colors)
      cards.rb, boards.rb  # Resource-specific commands
    resources/             # API resource modules
      base.rb              # HTTP helpers, safe_id, compact_params
      cards.rb, boards.rb  # Resource implementations
spec/
  spec_helper.rb           # RSpec + VCR + WebMock config
  superthread/             # Unit tests mirror lib/ structure
  fixtures/vcr_cassettes/  # Recorded HTTP responses
```

## Code Style Guidelines

### File Headers

Every Ruby file should start with the frozen string literal pragma:

```ruby
# frozen_string_literal: true
```

Note: Ruby 3.4+ emits deprecation warnings when mutating strings in files without
this pragma. Ruby 4.0 will likely freeze strings by default, making this optional.

### Imports/Requires

Order requires (no blank lines between groups):
1. Standard library (`json`, `yaml`, `fileutils`)
2. Third-party gems (`faraday`, `thor`)
3. Relative files (`require_relative`)

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | snake_case | `cards.rb`, `spec_helper.rb` |
| Classes/Modules | PascalCase | `Client`, `ApiError` |
| Methods | snake_case | `find_by_id`, `create_card` |
| Variables | snake_case | `workspace_id`, `response` |
| Constants | SCREAMING_SNAKE | `DEFAULT_BASE_URL`, `VERSION` |
| Predicates | trailing `?` | `archived?`, `watching?` |

### Method Signatures

Prefer keyword arguments for optional parameters:

```ruby
def create(workspace_id, space_id:, title:, **params)  # Good
def list(workspace_id, space_id:, archived: nil)       # Good - optional with defaults
def create(workspace_id, title, description = nil)     # Avoid - positional optional
```

## Response Objects

API responses are wrapped in typed `Superthread::Object` subclasses (Stripe-style pattern).

### Using Response Objects

```ruby
# Get a card - returns Superthread::Objects::Card
card = client.cards.find(workspace_id, card_id)

# Dot notation access
card.title              # => "My Card"
card.status             # => "started"
card.priority           # => 1

# Hash-like access also works
card[:title]            # => "My Card"
card["title"]           # => "My Card"

# Predicate methods
card.archived?          # => false
card.watching?          # => true

# Time helpers (converts Unix ms to Time)
card.created_at         # => 2024-01-15 10:30:00 -0800
card.due_time           # => 2024-01-20 17:00:00 -0800

# Nested objects
card.members.first.role # => "admin"
card.tags.map(&:name)   # => ["bug", "urgent"]

# Convert to plain hash
card.to_h               # => { id: "123", title: "My Card", ... }
```

### Collections

List endpoints return `Superthread::Objects::Collection`:

```ruby
cards = client.cards.assigned(workspace_id, user_id: user_id)

cards.each { |card| puts card.title }
cards.count             # => 5
cards.first             # => #<Superthread::Objects::Card ...>
cards.empty?            # => false
cards.to_h              # => [{ id: "1", ... }, { id: "2", ... }]
```

### Adding a New Object Type

1. Create `lib/superthread/objects/new_type.rb`:

```ruby
# frozen_string_literal: true

module Superthread
  module Objects
    class NewType < Superthread::Object
      OBJECT_NAME = "new_type"
      Superthread::Object.register_type(OBJECT_NAME, self)

      # Define attr_reader for common fields
      attr_reader :id, :title, :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @title = @data[:title]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Add helper methods
      def created_at
        @time_created && Time.at(@time_created / 1000.0)
      end
    end
  end
end
```

2. Update the resource to return the typed object:

```ruby
def find(workspace_id, new_type_id)
  ws = safe_id("workspace_id", workspace_id)
  id = safe_id("new_type_id", new_type_id)
  get_object("/#{ws}/new_types/#{id}",
    object_class: Objects::NewType, unwrap_key: :new_type)
end
```

## Resource Pattern

All API resources inherit from `Resources::Base`:

```ruby
def find(workspace_id, card_id)
  ws = safe_id("workspace_id", workspace_id)
  card = safe_id("card_id", card_id)
  get_object("/#{ws}/cards/#{card}",
    object_class: Objects::Card, unwrap_key: :card)
end

def list(workspace_id, space_id:)
  ws = safe_id("workspace_id", workspace_id)
  get_collection("/#{ws}/boards", params: { project_id: space_id },
    item_class: Objects::Board, items_key: :boards)
end
```

### Key Helpers

| Method | Purpose |
|--------|---------|
| `safe_id(name, value)` | Validates IDs, prevents path traversal |
| `compact_params(**args)` | Filters nil values from params hash |
| `get_object`, `post_object`, etc. | HTTP verbs returning typed objects |
| `get_collection`, `post_collection` | HTTP verbs returning collections |
| `http_get`, `http_post`, etc. | HTTP verbs returning raw hashes |
| `success_response` | Returns `{ success: true }` for delete operations |

## Error Handling

Errors are created via factory method with body-based subtyping (Octokit-style):

```ruby
# Error hierarchy
Superthread::Error                    # Base error
  Superthread::ConfigurationError     # Config issues (client-side)
  Superthread::PathValidationError    # ID validation (client-side)
  Superthread::ApiError               # HTTP errors (base)
    Superthread::ClientError          # 4xx errors
      Superthread::AuthenticationError  # 401
      Superthread::ForbiddenError       # 403
      Superthread::NotFoundError        # 404
      Superthread::ValidationError      # 400, 422
      Superthread::RateLimitError       # 429
    Superthread::ServerError          # 5xx errors

# Catching errors
begin
  client.cards.find(workspace_id, card_id)
rescue Superthread::NotFoundError => e
  puts "Card not found: #{e.message}"
  puts "HTTP Status: #{e.status}"
rescue Superthread::RateLimitError => e
  sleep e.retry_after || 60
  retry
rescue Superthread::ApiError => e
  puts "API error: #{e.message}"
end
```

## CLI Output Format

CLI uses gh-style formatting with colored tables and `--json` flag for scripting.

### Output Methods

```ruby
# Single item - shows key-value pairs (or JSON with --json)
output_item card, fields: %i[id title status priority]

# Collection - shows table (or JSON array with --json)
output_list cards, columns: %i[id title status]

# Success message (or JSON with --json)
output_success "Card #{card_id} deleted"

# Legacy support (auto-detects type)
output data
```

### CLI Command Pattern

```ruby
desc "get CARD_ID", "Get card details"
def get(card_id)
  card = client.cards.find(workspace_id, card_id)
  output_item card, fields: %i[id title status priority list_title]
end

desc "assigned USER_ID", "Get cards assigned to a user"
option :board_id, type: :string, desc: "Filter by board"
def assigned(user_id)
  cards = client.cards.assigned(
    workspace_id,
    user_id: user_id,
    **symbolized_options(:board_id, :project_id)
  )
  output_list cards, columns: %i[id title status priority]
end

desc "delete CARD_ID", "Delete a card"
def delete(card_id)
  client.cards.destroy(workspace_id, card_id)
  output_success "Card #{card_id} deleted"
end
```

### Helper: symbolized_options

Use `symbolized_options` instead of `options.slice(...).transform_keys(&:to_sym)`:

```ruby
# Before (verbose)
client.cards.create(workspace_id,
  **options.slice(:title, :board_id).transform_keys(&:to_sym))

# After (clean)
client.cards.create(workspace_id,
  **symbolized_options(:title, :board_id))
```

## Documentation

Use YARD-style comments for public methods:

```ruby
# Creates a new card in the specified workspace.
# API: POST /:workspace/cards
#
# @param workspace_id [String] Workspace ID
# @param params [Hash] Card creation parameters
# @option params [String] :title Card title (required)
# @return [Superthread::Objects::Card] Created card
def create(workspace_id, **params)
```

## Testing

Tests use RSpec with VCR for HTTP recording. Use `expect` syntax (not `should`):

```ruby
RSpec.describe Superthread::Resources::Cards do
  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#find" do
    it "returns a Card object", vcr: { cassette_name: "cards/find" } do
      result = client.cards.find("workspace-1", "card-123")
      expect(result).to be_a(Superthread::Objects::Card)
      expect(result.id).to eq("card-123")
      expect(result.title).to eq("Test Card")
    end
  end
end
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPERTHREAD_API_KEY` | API authentication key |
| `SUPERTHREAD_WORKSPACE_ID` | Default workspace ID |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: https://api.superthread.com/v1) |

## Adding a New Resource

1. Create object class in `lib/superthread/objects/new_resource.rb`
2. Create resource class in `lib/superthread/resources/new_resource.rb` inheriting from `Base`
3. Add to client composition in `lib/superthread/client.rb`
4. Create CLI commands in `lib/superthread/cli/new_resource.rb`
5. Register subcommand in `lib/superthread/cli/main.rb`
6. Add specs in `spec/superthread/resources/new_resource_spec.rb`

## Key Design Decisions

1. **Rich Objects over Hashes**: API responses are wrapped in typed objects for better DX (dot notation, helper methods, IDE support)

2. **Hybrid Typing**: Objects use `attr_reader` for common fields but fall back to `method_missing` for unknown fields (balance of type safety and flexibility)

3. **Factory Error Pattern**: `ApiError.from_response` examines both status code and body to create the most specific error type

4. **gh-style CLI**: Human-readable colored output by default, `--json` flag for scripting/piping

5. **No Monkey-patching**: String#truncate and similar utilities are in the Formatter module, not patched onto core classes
