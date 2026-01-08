# AGENTS.md - Superthread Ruby Gem

Guidelines for AI coding agents working in this repository.

## Project Overview

Ruby gem providing a library and CLI for the Superthread project management API.
- **Language:** Ruby >= 3.1.0
- **CLI Framework:** Thor
- **HTTP Client:** Faraday
- **Autoloading:** Zeitwerk
- **Style:** StandardRB (RuboCop-based)

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
bundle exec bin/st cards list
```

## Directory Structure

```
lib/
  superthread.rb           # Entry point, Zeitwerk loader setup
  superthread/
    version.rb             # VERSION constant
    error.rb               # Error class hierarchy
    client.rb              # Main API client (composition root)
    configuration.rb       # Config file and env var handling
    connection.rb          # Faraday HTTP wrapper
    cli/                   # Thor CLI commands
      base.rb              # Shared options and helpers
      main.rb              # Command routing
      cards.rb, boards.rb  # Resource-specific commands
    resources/             # API resource modules
      base.rb              # HTTP helpers, safe_id, build_params
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
| Predicates | trailing `?` | `exit_on_failure?` |

### Method Signatures

Prefer keyword arguments for optional parameters:

```ruby
def create(workspace_id, space_id:, title:, **params)  # Good
def list(workspace_id, space_id:, archived: nil)       # Good - optional with defaults
def create(workspace_id, title, description = nil)     # Avoid - positional optional
```

### Resource Pattern

All API resources inherit from `Resources::Base`:

```ruby
def find(workspace_id, card_id)
  ws = safe_id("workspace_id", workspace_id)
  card = safe_id("card_id", card_id)
  http_get("/#{ws}/cards/#{card}")
end
```

Key helpers:
- `safe_id(name, value)` - Validates IDs, prevents path traversal
- `build_params(**args)` - Filters nil values from params hash
- `http_get`, `http_post`, `http_patch`, `http_delete` - HTTP verbs

### Error Handling

Use the error hierarchy in `lib/superthread/error.rb`:

```ruby
raise Superthread::ConfigurationError, "API key required"
raise Superthread::NotFoundError.new("Card not found", status: 404, body: response)
raise Superthread::PathValidationError, "workspace_id must be non-empty"
```

Error classes: `Error`, `ConfigurationError`, `ApiError`, `AuthenticationError`,
`ForbiddenError`, `NotFoundError`, `ValidationError`, `RateLimitError`, `PathValidationError`

### Documentation

Use YARD-style comments for public methods:

```ruby
# Creates a new card in the specified workspace.
# API: POST /:workspace/cards
#
# @param workspace_id [String] Workspace ID
# @param params [Hash] Card creation parameters
# @option params [String] :title Card title (required)
# @return [Hash] Created card data
def create(workspace_id, **params)
```

### Testing

Tests use RSpec with VCR for HTTP recording. Use `expect` syntax (not `should`):

```ruby
RSpec.describe Superthread::Resources::Cards do
  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#find" do
    it "returns the card", vcr: { cassette_name: "cards/find" } do
      result = client.cards.find("workspace-1", "card-123")
      expect(result).to include("id" => "card-123")
    end
  end
end
```

### CLI Commands

Thor commands follow this pattern:

```ruby
desc "create", "Create a new card"
option :title, type: :string, required: true, desc: "Card title"
def create
  result = client.cards.create(workspace_id, **options_hash)
  output result
end
```

### Private Methods

Use `private` keyword on its own line:

```ruby
def public_method
  helper_method
end

private

def helper_method
  # implementation
end
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPERTHREAD_API_KEY` | API authentication key |
| `SUPERTHREAD_WORKSPACE_ID` | Default workspace ID |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: https://api.superthread.com/v1) |

## Adding a New Resource

1. Create `lib/superthread/resources/new_resource.rb` inheriting from `Base`
2. Add to client composition in `lib/superthread/client.rb`
3. Create CLI commands in `lib/superthread/cli/new_resource.rb`
4. Register subcommand in `lib/superthread/cli/main.rb`
5. Add specs in `spec/superthread/resources/new_resource_spec.rb`
