# Card Search Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `suth cards search TERM` with rich output and improve `suth search query` with `--status` and `--limit` options.

**Architecture:** The search resource gets pagination support (cursor-following with `limit:` param). A new `cards search` CLI command wraps the search API, fetches full card details for each result, and displays them with the same rich columns as `cards list`. The existing `search query` command gains `--status` and `--limit`.

**Tech Stack:** Ruby, Thor CLI, Faraday HTTP, Shale models, RSpec

**Spec:** `docs/superpowers/specs/2026-03-16-card-search-design.md`

---

## Chunk 1: Foundation — Pagination and `--limit` support

### Task 1: Add nil guard to `output_list` for unlimited results

**Files:**
- Modify: `lib/superthread/cli/base.rb:137-166`

- [ ] **Step 1: Write the failing test**

Add to `spec/integration/cli/search_spec.rb`:

```ruby
describe "search query with --limit 0" do
  before do
    stub_api_get("test_workspace/search", response: ApiFixtures::Search::RESULTS, query: {query: "test"})
  end

  it "shows all results with --limit 0" do
    result = run_cli("search", "query", "test", "--limit=0")

    expect(result[:exit_code]).to eq(0)
    expect(result[:stdout]).to include("Auth Module")
    expect(result[:stdout]).to include("Login Flow")
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/integration/cli/search_spec.rb -v`
Expected: Tests pass (since limit 0 currently falls through to default 50, which still shows 2 results). This test establishes the baseline.

- [ ] **Step 3: Add nil guard to `output_list`**

In `lib/superthread/cli/base.rb`, modify `output_list`:

```ruby
def output_list(items, columns: nil, headers: {})
  all_items = items.respond_to?(:items) ? items.items : Array(items)
  limit = effective_limit
  truncated = limit && all_items.length > limit
  visible = truncated ? all_items.first(limit) : all_items

  # ... rest unchanged
end
```

Change line 140 from `truncated = all_items.length > limit` to `truncated = limit && all_items.length > limit`.
Change line 141 from `visible = truncated ? all_items.first(limit) : all_items` — no change needed, already correct with `truncated` guard.

Also update the truncation footer (line 161-163) to be guarded:

```ruby
if truncated && limit
  say "Showing #{limit} of #{all_items.length}. Use --limit to adjust.", :yellow
end
```

- [ ] **Step 4: Run tests to verify nothing broke**

Run: `bundle exec rspec`
Expected: All tests pass (this is a backward-compatible change — `effective_limit` still returns an Integer for all existing commands).

- [ ] **Step 5: Commit**

```bash
git add lib/superthread/cli/base.rb spec/integration/cli/search_spec.rb
git commit -m "refactor: support nil effective_limit in output_list for unlimited results"
```

### Task 2: Add pagination to `Resources::Search#query`

**Files:**
- Modify: `lib/superthread/resources/search.rb`
- Create: `spec/superthread/resources/search_spec.rb`

- [ ] **Step 1: Write the failing test**

Create `spec/superthread/resources/search_spec.rb`:

```ruby
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Superthread::Resources::Search do
  include StubHelpers

  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#query" do
    it "returns search results" do
      stub_api_get("test_workspace/search",
        response: ApiFixtures::Search::RESULTS,
        query: {query: "auth"})

      results = client.search.query("test_workspace", query: "auth")

      expect(results.count).to eq(2)
      expect(results.first[:title]).to eq("Auth Module")
    end

    it "follows cursor for pagination" do
      page1 = {
        count: 2,
        cursor: "page2cursor",
        results: [{card: {id: "card-1", title: "Result 1"}}]
      }
      page2 = {
        count: 2,
        cursor: "",
        results: [{card: {id: "card-2", title: "Result 2"}}]
      }

      # Use to_return chaining to return page1 first, then page2
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/search")
        .with(query: hash_including("query" => "test"))
        .to_return(
          {status: 200, body: page1.to_json, headers: {"Content-Type" => "application/json"}},
          {status: 200, body: page2.to_json, headers: {"Content-Type" => "application/json"}}
        )

      results = client.search.query("test_workspace", query: "test")

      expect(results.count).to eq(2)
      expect(results.map { |r| r[:title] }).to eq(["Result 1", "Result 2"])
    end

    it "stops at limit" do
      page1 = {
        count: 3,
        cursor: "page2cursor",
        results: [
          {card: {id: "card-1", title: "Result 1"}},
          {card: {id: "card-2", title: "Result 2"}}
        ]
      }

      stub_api_get("test_workspace/search",
        response: page1,
        query: {query: "test"})

      results = client.search.query("test_workspace", query: "test", limit: 1)

      expect(results.count).to eq(1)
      expect(results.first[:title]).to eq("Result 1")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/superthread/resources/search_spec.rb -v`
Expected: FAIL — `query` doesn't accept `limit:` param yet, and doesn't follow cursors.

- [ ] **Step 3: Implement pagination in `Resources::Search#query`**

Replace the `query` method in `lib/superthread/resources/search.rb`:

```ruby
# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for search operations.
    #
    # Provides methods for searching across workspace entities
    # (cards, pages, boards, etc.) via the Superthread API.
    class Search < Base
      # Searches across workspace entities.
      #
      # Follows pagination cursors automatically. When limit is provided,
      # stops after accumulating that many results.
      #
      # @param workspace_id [String] the workspace identifier
      # @param query [String] the search query string
      # @param limit [Integer, nil] max results to return (nil = no limit)
      # @param params [Hash{Symbol => Object}] optional search parameters
      # @option params [String] :field the field to search (title, content)
      # @option params [Array<String>] :types entity types to include (board, card, page, etc.)
      # @option params [Array<String>] :statuses status values to filter by
      # @option params [String] :space_id the space identifier to filter by
      # @option params [Boolean] :archived when true, includes archived entities
      # @option params [Boolean] :grouped when true, groups results by type (default: false)
      # @return [Superthread::Objects::Collection] the search results
      def query(workspace_id, query:, limit: nil, **params)
        ws = safe_id("workspace_id", workspace_id)
        grouped = params[:grouped].nil? ? false : params[:grouped]
        all_results = []
        cursor = nil

        loop do
          search_params = compact_params(
            query: query,
            project_id: params[:space_id],
            grouped: grouped,
            cursor: cursor,
            **params.except(:space_id, :grouped)
          )
          response = http_get("/#{ws}/search", params: search_params)

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
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/superthread/resources/search_spec.rb -v`
Expected: All 3 tests pass.

- [ ] **Step 5: Run full suite**

Run: `bundle exec rspec`
Expected: All tests pass (existing search CLI tests still work since `limit:` defaults to nil).

- [ ] **Step 6: Run linters**

Run: `bundle exec standardrb --fix lib/superthread/resources/search.rb spec/superthread/resources/search_spec.rb && bundle exec yard-lint lib/superthread/resources/search.rb`

- [ ] **Step 7: Commit**

```bash
git add lib/superthread/resources/search.rb spec/superthread/resources/search_spec.rb
git commit -m "feat: add pagination support to search resource (#61)"
```

### Task 3: Add `--status` and `--limit` to `search query` CLI

**Files:**
- Modify: `lib/superthread/cli/search.rb`
- Modify: `spec/integration/cli/search_spec.rb`

- [ ] **Step 1: Write failing tests**

Add to `spec/integration/cli/search_spec.rb`:

```ruby
describe "search query with --status" do
  before do
    stub_api_get("test_workspace/search",
      response: ApiFixtures::Search::RESULTS_TYPED,
      query: {query: "auth"})
  end

  it "accepts status filter" do
    result = run_cli("search", "query", "auth", "--status=open,started")

    expect(result[:exit_code]).to eq(0)
    expect(result[:stdout]).to include("Auth Module")
  end
end

describe "search query with --limit" do
  before do
    stub_api_get("test_workspace/search",
      response: ApiFixtures::Search::RESULTS,
      query: {query: "test"})
  end

  it "passes limit to resource" do
    result = run_cli("search", "query", "test", "--limit=10")

    expect(result[:exit_code]).to eq(0)
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/integration/cli/search_spec.rb -v`
Expected: FAIL — `--status` option doesn't exist yet.

- [ ] **Step 3: Update `search.rb` CLI**

Replace `lib/superthread/cli/search.rb`:

```ruby
# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for search operations.
    class Search < Base
      desc "query SEARCH_TERM", "Search across workspace"
      option :field, type: :string, enum: %w[title content], desc: "Field to search in"
      option :types, type: :string, desc: "Entity types to search (comma-separated: board,card,page,project,epic,note)"
      option :status, type: :string, desc: "Status filter (comma-separated, e.g., open,started)"
      option :space, type: :string, aliases: "-s", desc: "Space to filter by (ID or name)"
      option :include_archived, type: :boolean, desc: "Include archived items"
      option :grouped, type: :boolean, desc: "Group results by type"
      # Searches across all entities in the workspace.
      #
      # @param search_term [String] the text to search for
      # @return [void]
      def query(search_term)
        handle_error do
          types = options[:types]&.split(",")&.map(&:strip)
          statuses = options[:status]&.split(",")&.map(&:strip)
          results = client.search.query(
            workspace_id,
            query: search_term,
            field: options[:field],
            types: types,
            statuses: statuses,
            space_id: space_id,
            archived: options[:include_archived],
            grouped: options[:grouped],
            limit: effective_limit
          )
          output_list results, columns: %i[result_type id title], headers: {id: "ID"}
        end
      end

      private

      # Override Base#effective_limit for search-specific defaults.
      #
      # @return [Integer, nil] the limit (nil = unlimited when --limit 0)
      def effective_limit
        limit = options[:limit]
        return nil if limit == 0
        (limit.is_a?(Integer) && limit > 0) ? limit : 30
      end
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/integration/cli/search_spec.rb -v`
Expected: All tests pass.

- [ ] **Step 5: Run linters**

Run: `bundle exec standardrb --fix lib/superthread/cli/search.rb spec/integration/cli/search_spec.rb`

- [ ] **Step 6: Commit**

```bash
git add lib/superthread/cli/search.rb spec/integration/cli/search_spec.rb
git commit -m "feat: add --status and --limit to search query (#61)"
```

## Chunk 2: `cards search` command

### Task 4: Add fixtures for card search

**Files:**
- Modify: `spec/support/api_fixtures.rb`

- [ ] **Step 1: Add search fixtures that return card results**

Add to `spec/support/api_fixtures.rb` inside the `Search` module:

```ruby
CARD_RESULTS = {
  count: 2,
  cursor: "",
  results: [
    {card: {id: "card-auth", title: "Auth Module", board_id: "1", list_id: "1", project_id: "1"}},
    {card: {id: "card-login", title: "Login Flow", board_id: "1", list_id: "2", project_id: "1"}}
  ]
}.freeze

CARD_RESULTS_EMPTY = {
  count: 0,
  cursor: "",
  results: []
}.freeze
```

Also add card GET fixtures for enrichment (the search results get fetched individually). Add to `Cards` module:

```ruby
SEARCH_CARD_1 = {
  card: {
    id: "card-auth",
    title: "Auth Module",
    status: "started",
    priority: 2,
    board_id: "10",
    board_title: "Frontend Board",
    list_id: "101",
    list_title: "In Progress",
    time_created: 1705312200000,
    time_updated: 1705399000000,
    members: [{user_id: "u123abc", role: "assignee"}],
    tags: [],
    checklists: []
  }
}.freeze

SEARCH_CARD_2 = {
  card: {
    id: "card-login",
    title: "Login Flow",
    status: "open",
    priority: 3,
    board_id: "10",
    board_title: "Frontend Board",
    list_id: "100",
    list_title: "To Do",
    time_created: 1705312200000,
    time_updated: 1705312200000,
    members: [],
    tags: [],
    checklists: []
  }
}.freeze
```

- [ ] **Step 2: Run full suite to verify fixtures don't break anything**

Run: `bundle exec rspec`
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add spec/support/api_fixtures.rb
git commit -m "test: add fixtures for card search (#61)"
```

### Task 5: Implement `cards search` command

**Files:**
- Modify: `lib/superthread/cli/cards.rb`
- Modify: `spec/integration/cli/cards_spec.rb`

- [ ] **Step 1: Write failing tests**

Add to `spec/integration/cli/cards_spec.rb`:

```ruby
describe "cards search TERM" do
  before do
    stub_api_get("test_workspace/search",
      response: ApiFixtures::Search::CARD_RESULTS,
      query: {query: "auth"})
    stub_api_get("test_workspace/cards/card-auth",
      response: ApiFixtures::Cards::SEARCH_CARD_1)
    stub_api_get("test_workspace/cards/card-login",
      response: ApiFixtures::Cards::SEARCH_CARD_2)
    stub_api_get("teams/test_workspace/members", response: ApiFixtures::Users::MEMBERS)
  end

  it "searches for cards and shows rich output" do
    result = run_cli("cards", "search", "auth")

    expect(result[:exit_code]).to eq(0)
    expect(result[:stdout]).to include("Auth Module")
    expect(result[:stdout]).to include("Login Flow")
    expect(result[:stdout]).to include("Frontend Board")
    expect(result[:stdout]).to include("In Progress")
  end

  it "outputs JSON with --json flag" do
    json = cli_json("cards", "search", "auth")

    expect(json).to be_an(Array)
    expect(json.length).to eq(2)
    expect(json.first["title"]).to eq("Auth Module")
    expect(json.first["board_title"]).to eq("Frontend Board")
  end
end

describe "cards search with no results" do
  before do
    stub_api_get("test_workspace/search",
      response: ApiFixtures::Search::CARD_RESULTS_EMPTY,
      query: {query: "nonexistent"})
  end

  it "shows no results message" do
    result = run_cli("cards", "search", "nonexistent")

    expect(result[:exit_code]).to eq(0)
    expect(result[:stdout]).to include("No cards found")
  end
end

describe "cards search skips deleted cards" do
  before do
    stub_api_get("test_workspace/search",
      response: ApiFixtures::Search::CARD_RESULTS,
      query: {query: "auth"})
    stub_api_error(:get, "test_workspace/cards/card-auth", status: 404, error: "not found")
    stub_api_get("test_workspace/cards/card-login",
      response: ApiFixtures::Cards::SEARCH_CARD_2)
    stub_api_get("teams/test_workspace/members", response: ApiFixtures::Users::MEMBERS)
  end

  it "shows remaining cards when some are not found" do
    result = run_cli("cards", "search", "auth")

    expect(result[:exit_code]).to eq(0)
    expect(result[:stdout]).not_to include("Auth Module")
    expect(result[:stdout]).to include("Login Flow")
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/integration/cli/cards_spec.rb -v`
Expected: FAIL — `search` command doesn't exist on Cards yet.

- [ ] **Step 3: Implement the search command**

Add to `lib/superthread/cli/cards.rb` after the `list` command (before `get`). Also check the existing `Members::LIST` fixture exists — look at `spec/support/api_fixtures.rb` for the `Members` module.

Add the command:

```ruby
desc "search TERM", "Search for cards across boards and spaces"
option :space, type: :string, aliases: "-s", desc: "Space to filter by (ID or name)"
option :status, type: :string, desc: "Status filter (comma-separated)"
option :field, type: :string, enum: %w[title content], desc: "Search in title or content"
option :include_archived, type: :boolean, desc: "Include archived cards"
# Search for cards by keyword with rich output.
#
# @param term [String] the search term
# @return [void]
def search(term)
  handle_error do
    fetch_limit = if options[:limit] == 0
      nil
    elsif options[:limit].is_a?(Integer) && options[:limit] > 0
      options[:limit]
    else
      30
    end

    statuses = options[:status]&.split(",")&.map(&:strip)
    results = client.search.query(
      workspace_id,
      query: term,
      types: ["card"],
      statuses: statuses,
      field: options[:field],
      space_id: (space_id if options[:space]),
      archived: options[:include_archived],
      limit: fetch_limit
    )

    card_ids = results.map { |r| r[:id] }.compact
    if card_ids.empty?
      say "No cards found matching '#{term}'.", :yellow unless options[:quiet]
      return
    end

    cards = card_ids.filter_map do |id|
      client.cards.find(workspace_id, id)
    rescue Superthread::NotFoundError, Superthread::ForbiddenError
      nil
    end

    if cards.empty?
      say "No cards found matching '#{term}'.", :yellow unless options[:quiet]
      return
    end

    enrich_members(cards)
    output_list cards, columns: %i[id title priority list_title board_title members],
      headers: {id: "CARD_ID", list_title: "LIST", board_title: "BOARD"}
  end
end
```

Also add the private `effective_limit` override in the `private` section of Cards, after `enrich_members`. This ensures both the API fetch limit and `output_list` display limit are in sync:

```ruby
# Override Base#effective_limit for --limit 0 (unlimited) support.
# When --limit 0, returns nil to disable truncation in output_list.
# Other card commands never use --limit 0, so this is safe.
#
# @return [Integer, nil] the limit (nil = unlimited when --limit 0)
def effective_limit
  return nil if options[:limit] == 0
  super
end
```

In the `search` method, compute the fetch limit inline (default 30 for search, different from Base's 50):

```ruby
fetch_limit = if options[:limit] == 0
  nil
elsif options[:limit].is_a?(Integer) && options[:limit] > 0
  options[:limit]
else
  30
end
```

Then pass `limit: fetch_limit` to the search resource. The `effective_limit` override handles `output_list` truncation for the `--limit 0` case.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/integration/cli/cards_spec.rb -v`
Expected: New search tests pass.

- [ ] **Step 5: Run full suite**

Run: `bundle exec rspec`
Expected: All tests pass.

- [ ] **Step 6: Run linters**

Run: `bundle exec standardrb --fix lib/superthread/cli/cards.rb spec/integration/cli/cards_spec.rb && bundle exec yard-lint lib/superthread/cli/cards.rb`

- [ ] **Step 7: Commit**

```bash
git add lib/superthread/cli/cards.rb spec/integration/cli/cards_spec.rb
git commit -m "feat: add cards search command with rich output (#61)"
```

## Chunk 3: Documentation and cleanup

### Task 6: Update CLI skill and run final verification

**Files:**
- Modify: `skills/superthread/SKILL.md`

- [ ] **Step 1: Update the CLI skill**

Add under the Cards section in `skills/superthread/SKILL.md`, near the existing card commands:

```
suth cards search TERM [-s SPACE] [--status STATUS] [--field title|content] [--include-archived] [--limit N]
```

Update the Search section to show new options:

```
suth search query TERM [--types card,page,...] [--status open,started] [--field title|content] [-s SPACE] [--include-archived] [--limit N]
```

- [ ] **Step 2: Run full test suite**

Run: `bundle exec rspec`
Expected: All tests pass.

- [ ] **Step 3: Run all linters**

Run: `bundle exec standardrb --fix && bundle exec yard-lint lib/`

- [ ] **Step 4: Commit**

```bash
git add skills/superthread/SKILL.md
git commit -m "docs: document cards search and search query improvements (#61)"
```

- [ ] **Step 5: Close the issue**

After all tests pass and all commits are on master:

```bash
gh issue close 61 --comment "Implemented in cards search command with rich output, pagination, and status filtering."
```
