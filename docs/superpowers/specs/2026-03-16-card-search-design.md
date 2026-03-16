# Card Search & Search Improvements

**Date:** 2026-03-16
**Issue:** #61 — Add card search command
**Status:** Design

## Problem

Finding cards requires knowing which board or sprint they're on. Users (and agents) can't say "find me the card about X" without first navigating the board/space hierarchy. The existing `suth search query` command exists but returns minimal data (type, ID, title) — not enough to identify cards without follow-up calls.

## Solution

### 1. `suth cards search TERM`

A convenience command that searches for cards and returns rich, actionable results. The `--types` option is intentionally not exposed — this command always searches cards only.

**Usage:**

```bash
suth cards search "login timeout"
suth cards search "deploy" --space "Frontend"
suth cards search "bug" --status open,started
suth cards search "auth" --field title
suth cards search "deploy" --include-archived
suth cards search "deploy" --limit 50
suth cards search "all bugs" --limit 0    # no limit, fetch all
```

**Options:**

| Option | Type | Description |
|--------|------|-------------|
| `--space`, `-s` | string | Space to filter by (ID or name, resolved to ID before passing to API) |
| `--status` | string | Comma-separated status values (passed through to API as-is) |
| `--field` | string | Search in `title` or `content` (enum-validated, same as `search query`) |
| `--include-archived` | boolean | Include archived cards |
| `--limit`, `-L` | integer | Max results to fetch and display (default: 30, 0 = no limit) |

**Default output:**

```
CARD_ID   TITLE                  PRIORITY  LIST          BOARD           MEMBERS
card-123  Fix login timeout      urgent    In Progress   Frontend Board  Clint, Stacey
card-456  Add search command     normal    To Do         CLI Board       Steve
```

**`--json` output:** Array of full card objects, same shape as `cards get`. Uses standard `output_list` behavior (truncation wrapper when results are limited).

**Internal flow:**

1. Call `client.search.query(workspace_id, query: term, types: ["card"], statuses:, field:, space_id:, archived:, limit:)` — the resource handles cursor-following internally and returns up to `limit` results
2. Extract card IDs from search results
3. Call `client.cards.find(workspace_id, card_id)` for each result (sequential; parallelism deferred to caching work in #10)
4. Skip any cards that return 404/403 (may have been deleted between search and fetch)
5. Enrich members with display names (reuse existing `enrich_members` helper)
6. Display via `output_list` with columns: `id`, `title`, `priority`, `list_title`, `board_title`, `members`

### 2. Improvements to `suth search query`

The API supports parameters the CLI doesn't expose yet.

**Changes:**
- Add `--status` option that accepts comma-separated values, passed through as an array
- Add `--limit` / `-L` option (default: 30, 0 = no limit) with automatic cursor-following

```bash
suth search query "auth" --status open,started
suth search query "deploy" --limit 50
```

## `--limit` and the global `Base.class_option :limit`

`Base` already declares a global `--limit` option (default: 50) used by `effective_limit` for display truncation in `output_list`. For search commands, `--limit` controls **fetching** — how many results to accumulate via pagination — not just display.

**Design:** Search commands override `effective_limit` (defined in `Base`) to default to 30 instead of 50, and to support `--limit 0` (unlimited). Since the fetch is pre-limited to the same count, `output_list` truncation won't discard results. Other commands are unaffected — they inherit the original `effective_limit` from `Base`.

```ruby
# In cards.rb search command and search.rb query command,
# override the Base method:
def effective_limit
  limit = options[:limit]
  return nil if limit == 0  # unlimited
  (limit.is_a?(Integer) && limit > 0) ? limit : 30
end
```

When `effective_limit` returns `nil`, `output_list` skips truncation (requires a small guard in `output_list` to handle `nil`).

## Pagination in `Resources::Search`

Currently `Resources::Search#query` discards the cursor from the API response. Add a `limit:` parameter to `query` that handles cursor-following internally:

Illustrative pseudocode (actual implementation will follow existing `query` method patterns):

```ruby
def query(workspace_id, query:, limit: nil, **params)
  ws = safe_id("workspace_id", workspace_id)
  all_results = []
  cursor = nil

  loop do
    search_params = compact_params(query: query, cursor: cursor, **params.except(:limit))
    response = http_get("/#{ws}/search", params: search_params)

    # Unwrap results inline (same as existing pattern)
    results = (response[:results] || []).map do |item|
      result_type, data = item.first
      data.merge(result_type: result_type.to_s)
    end
    all_results.concat(results)

    cursor = response[:cursor]
    break if cursor.nil? || cursor.empty?
    break if limit && all_results.size >= limit
  end

  all_results = all_results.first(limit) if limit
  Objects::Collection.from_response(all_results)
end
```

This keeps pagination logic in the resource layer. CLI commands just pass `limit:` and get back a flat collection.

## Error Handling

- **No results:** Display `"No cards found matching 'TERM'"`.
- **Card fetch fails (404/403):** Skip that card, show the rest. Cards may be deleted between search and individual fetch.
- **Non-card results from API:** Silently skip (shouldn't happen with `types: ["card"]`).

## Performance

This command makes N+1 API calls (1 search + N card fetches) plus additional search calls for pagination. Sequential fetching is acceptable now. With `--limit 0`, there is no hard ceiling — the command will fetch until the API returns no more results. This matches the `gh` convention. Optimization via caching or parallelism is deferred to #10.

## Files to Change

| File | Change |
|------|--------|
| `lib/superthread/cli/base.rb` | Add nil guard in `output_list` for unlimited results |
| `lib/superthread/cli/cards.rb` | Add `search` subcommand |
| `lib/superthread/cli/search.rb` | Add `--status` and `--limit` options |
| `lib/superthread/resources/search.rb` | Add `limit:` param with cursor-following |
| `spec/integration/cli/cards_spec.rb` | Tests for `cards search` |
| `spec/integration/cli/search_spec.rb` | Tests for `--status` and `--limit` |
| `spec/superthread/resources/search_spec.rb` | New file: tests for pagination |
| `spec/support/api_fixtures.rb` | Add search + card fixtures |
| `skills/superthread/SKILL.md` | Document `cards search` and new options |

No changes needed to `client.rb` — reuses existing `search` and `cards` resources.

## Not in Scope

- Sorting options
- Caching layer (tracked in #10)
- Parallel card fetching (tracked in #10)
- Search for other entity types (pages, boards) — use `suth search query` with `--types`
