# YARD Documentation Guide

This project uses [yard-lint](https://github.com/mensfeld/yard-lint) to enforce documentation standards. Good documentation is critical for AI-assisted development — agents read YARD comments to understand code.

## Quick Start

```bash
# Check documentation
bundle exec yard-lint lib/

# Check with coverage stats
bundle exec yard-lint lib/ --stats

# Check only changed files (vs main branch)
bundle exec yard-lint lib/ --diff main

# Check only staged files
bundle exec yard-lint lib/ --staged
```

## What yard-lint Checks

### Documentation Must Exist

Every public class, module, and method needs documentation:

```ruby
# Good
# Retrieves a card by ID.
#
# @param card_id [String] the card identifier
# @return [Card] the retrieved card
def find(card_id)
  # ...
end

# Bad - no documentation
def find(card_id)
  # ...
end
```

### Parameters Need @param Tags

Every method parameter must have a corresponding `@param` tag:

```ruby
# Good
# @param workspace_id [String] the workspace identifier
# @param options [Hash] additional options
def list(workspace_id, options = {})

# Bad - missing @param for options
# @param workspace_id [String] the workspace identifier
def list(workspace_id, options = {})
```

### Block Parameters

Methods that take blocks need `@param` for the block and `@yieldparam`/`@yieldreturn` if applicable:

```ruby
# Good
# Executes a block with a spinner.
#
# @param title [String] spinner message
# @param block [Proc] the block to execute
# @yieldreturn [Object] result of the block
# @return [Object] the block's return value
def spin(title, &block)
  # ...
end
```

### Tag Ordering

Tags must appear in this order:

1. `@param` — method parameters
2. `@option` — options hash keys
3. `@yield` — block description
4. `@yieldparam` — block parameters
5. `@yieldreturn` — block return value
6. `@return` — method return value
7. `@raise` — exceptions that may be raised
8. `@see` — references
9. `@example` — usage examples
10. `@note` — additional notes
11. `@todo` — future work

```ruby
# Good order
# @param id [String] the identifier
# @return [Object] the result
# @raise [NotFoundError] if not found
# @note This method is slow

# Bad order - @raise before @return
# @param id [String] the identifier
# @raise [NotFoundError] if not found
# @return [Object] the result
```

### Collection Type Syntax

Use YARD's standard Hash syntax:

```ruby
# Good
# @param data [Hash{Symbol => Object}] the data hash
# @return [Array<String>] list of names

# Bad - wrong Hash syntax
# @param data [Hash<Symbol, Object>] the data hash
```

### Avoid Redundant Descriptions

Don't just restate the parameter name or type:

```ruby
# Good - adds meaning
# @param user_id [String] the ID of the user to look up

# Bad - just restates the name
# @param user_id [String] the user ID

# Bad - just restates the type
# @param name [String] a string
```

## Thor CLI Commands

For Thor-based CLI commands, YARD comments must go **after** all Thor DSL (`desc`, `option`, `method_option`) and **directly before** the method definition:

```ruby
# Good - docs after Thor DSL, before def
desc "get CARD_ID", "Get card details"
option :open, type: :boolean, aliases: "-o", desc: "Open in browser"
# Retrieves and displays details for a specific card.
#
# @param card_id [String] the card identifier
# @return [void]
def get(card_id)
  # ...
end

# Bad - docs between desc and option (YARD can't find them)
desc "get CARD_ID", "Get card details"
# This comment is in the wrong place!
# @param card_id [String] the card identifier
option :open, type: :boolean, aliases: "-o", desc: "Open in browser"
def get(card_id)
  # ...
end
```

## Common Patterns

### Void Methods

CLI commands that print output typically return void:

```ruby
# @return [void]
def list
  puts "..."
end
```

### Methods with Options Hash

Document each option with `@option`:

```ruby
# Creates a new card.
#
# @param workspace_id [String] workspace identifier
# @param attrs [Hash] card attributes
# @option attrs [String] :title card title
# @option attrs [String] :content card description
# @option attrs [String] :list_id target list
# @return [Card] the created card
def create(workspace_id, **attrs)
  # ...
end
```

### Boolean Methods

Methods ending in `?` must document their boolean return:

```ruby
# Checks if the collection is empty.
#
# @return [Boolean] true if no items in collection
def empty?
  @items.empty?
end
```

## Configuration

The `.yard-lint.yml` file configures validators and exclusions. Key settings:

```yaml
AllValidators:
  MinCoverage: 90.0  # Fail if below 90% documented

Documentation/UndocumentedObjects:
  ExcludedMethods:
    - 'initialize/0'  # Skip parameterless initialize
    - '/^_/'          # Skip underscore-prefixed methods

Tags/Order:
  EnforcedOrder:
    - param
    - option
    - yield
    - yieldparam
    - yieldreturn
    - return
    - raise
    - see
    - example
    - note
    - todo
```

## Troubleshooting

### "Empty comment line" errors

Remove lone `#` lines before class/module/def:

```ruby
# Bad
#
class Foo
end

# Good
class Foo
end
```

### "Unknown parameter name" errors

The `@param` tag name doesn't match the actual parameter:

```ruby
# Bad - @param says 'id' but param is 'card_id'
# @param id [String] the identifier
def find(card_id)

# Good
# @param card_id [String] the identifier
def find(card_id)
```

### Coverage not improving

Make sure you're documenting:
- The class/module itself (not just methods)
- All parameters including `&block`
- Return values with proper types

## Why Documentation Matters

In the age of AI-assisted development, documentation is code:

1. **AI agents read YARD comments** to understand what code does
2. **Incorrect docs reduce AI success rates** by up to 50%
3. **Type hints in `@param`/`@return`** help agents generate correct code
4. **`@example` blocks** provide working usage patterns

Good documentation makes the entire codebase more accessible to both humans and AI.

## Maintenance

### After Upgrading yard-lint

New versions may add validators. Update your config to include them:

```bash
bundle exec yard-lint --update
```

This adds new validators with their defaults while preserving your customizations.

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
bundle exec yard-lint lib/ --staged
```

This checks only staged files before each commit.

## CI Integration

Example GitHub Actions workflow:

```yaml
name: Documentation
on: [pull_request]
jobs:
  yard-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Needed for --diff mode
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Check documentation
        run: bundle exec yard-lint lib/ --diff origin/${{ github.base_ref }}
```

This checks only files changed in the PR, enforcing standards on new code.
