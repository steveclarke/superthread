# Shale Migration Tracker

This document tracks the migration from custom `Superthread::Object` classes to Shale models.

## Overview

We're migrating from a Stripe-style `Superthread::Object` pattern (method_missing, manual attr_reader)
to Shale::Mapper models for cleaner, type-safe serialization.

## Benefits of Shale

- **Type coercion**: Built-in support for `:string`, `:integer`, `:float`, `:boolean`, `:date`, `:time`
- **Declarative**: Clean attribute definitions without manual initialization
- **Multi-format**: JSON, YAML, TOML, CSV serialization out of the box
- **Nested models**: First-class support for nested objects and collections
- **Immutable-friendly**: Works well with readonly patterns

## Migration Strategy

1. **Keep both systems running**: New `Superthread::Model` base class alongside existing `Superthread::Object`
2. **Update client**: Detect Shale models and use `from_hash` for deserialization
3. **Migrate incrementally**: Convert one model at a time, starting with most-used
4. **Maintain compatibility**: Ensure `to_h`, `to_json`, predicates work the same way

## Migration Status

| Model | Status | Notes |
|-------|--------|-------|
| **Card** | Pending | Most complex - has nested members, tags, checklists |
| **Member** | Pending | Nested in Card |
| **LinkedCard** | Pending | Extends Card |
| **Board** | Pending | Has nested lists |
| **List** | Pending | Nested in Board |
| **User** | Pending | |
| **Project** | Pending | |
| **Space** | Pending | |
| **Sprint** | Pending | |
| **Comment** | Pending | |
| **Page** | Pending | |
| **Note** | Pending | |
| **Tag** | Pending | |
| **Checklist** | Pending | Has nested items |
| **ChecklistItem** | Pending | Nested in Checklist |
| **Collection** | Keep | Wrapper class, works with both systems |
| **Object** | Keep | Base fallback for untyped responses |

## Files Changed

### New Files
- `lib/superthread/model.rb` - Shale base class with helpers
- `lib/superthread/cli/ui.rb` - Gum-based terminal UI module
- `lib/superthread/models/` - New Shale model directory (once migration progresses)

### Modified Files
- `superthread.gemspec` - Added shale, gum dependencies
- `lib/superthread/client.rb` - Updated to detect Shale models

## Conversion Guide

### Before (Superthread::Object)

```ruby
class Card < Superthread::Object
  OBJECT_NAME = 'card'
  Superthread::Object.register_type(OBJECT_NAME, self)

  attr_reader :id, :title, :status, :priority, :time_created

  def initialize(data = {})
    super
    @id = @data[:id]
    @title = @data[:title]
    @status = @data[:status]
    @priority = @data[:priority]
    @time_created = @data[:time_created]
  end

  def created_at
    @time_created && Time.at(@time_created / 1000.0)
  end

  def archived?
    !!@data[:archived]
  end
end
```

### After (Shale)

```ruby
class Card < Superthread::Model
  attribute :id, Shale::Type::String
  attribute :title, Shale::Type::String
  attribute :status, Shale::Type::String
  attribute :priority, Shale::Type::Integer
  attribute :time_created, Shale::Type::Integer
  attribute :archived, Shale::Type::Value  # Can be hash or nil

  attribute :members, Member, collection: true
  attribute :tags, Tag, collection: true

  # Helper methods stay the same
  def created_at
    time_created && Time.at(time_created / 1000.0)
  end

  def archived?
    !!archived
  end
end
```

## Notes

- Shale uses `from_hash(data)` not `new(data)` for deserialization
- The `Superthread::Model` base class provides `to_h` compatibility
- Timestamps from API are Unix milliseconds - convert in helper methods
- Nested objects need their own Shale model definitions

## Testing

After each migration:
1. Run `bundle exec rspec spec/superthread/objects/MODEL_spec.rb`
2. Test CLI commands that use the model
3. Verify JSON output matches previous format
