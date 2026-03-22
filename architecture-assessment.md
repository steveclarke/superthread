# Architecture Assessment — Superthread

Generated: 2026-03-21 | Framework: Ruby gem (Thor CLI, Faraday HTTP, Shale models, Zeitwerk)

## Summary

Superthread is a well-structured Ruby gem with clean layered organization (CLI → Resources → Models), idiomatic framework usage, and consistent API interfaces across resources. The codebase aligns well with its stated philosophy of convention-driven development with MVC sensibilities — the CLI layer acts as a thin controller, resources handle API communication, and Shale models provide type-safe data representation.

The issues found are real but manageable. The most significant are a layer inversion where a model depends on the CLI formatter, a dual object system (legacy hash-wrapper vs. Shale models) that creates branching dispatch, and some dead code that creates confusion for readers. No critical issues were found — this is a healthy codebase with room for incremental cleanup.

**Finding counts:** Critical: 0 | High: 0 | Medium: 4 | Low: 6

## Lens Health

| Lens | Health |
|------|--------|
| Structural Organization | Good |
| Design Patterns | Good |
| Composition & Inheritance | Needs Attention |
| Coupling & Cohesion | Needs Attention |
| Framework Alignment | Good |
| API & Interface Design | Good |
| Duplication & Reuse | Needs Attention |

## Findings by Lens

### Structural Organization

**Health: Good**

Layer-by-layer organization (`cli/`, `models/`, `resources/`, `objects/`) is clean and consistent. CLI concerns are properly co-located under `cli/concerns/`. Models group shared behavior under `models/concerns/`. The spec tree mirrors the source tree. Zeitwerk autoloading is configured correctly.

### Design Patterns

**Health: Good**

Factory error pattern (`ApiError.from_response`) is well applied. The resource base class provides consistent HTTP helper methods. Shale model layer is a clean adapter. Concerns act as mixins for cross-cutting behavior. No forced or over-applied patterns detected.

### Composition & Inheritance

**Health: Needs Attention**

#### Finding: Dead code — Confirmable concern superseded by inline method in Base

- **Severity:** Medium
- **Location:** `lib/superthread/cli/concerns/confirmable.rb`, `lib/superthread/cli/base.rb:343-352`
- **What:** `Confirmable` defines a `confirming` method using `options[:force]`, but `Base` defines its own `confirming` using `options[:skip_confirm]`. The concern is never included anywhere. The option name mismatch means including it would silently shadow `Base#confirming` with different semantics. The docstring example shows `include Concerns::Confirmable` — a pattern that was planned but never executed.
- **Why it matters:** Creates confusion for any developer who reads it and assumes it's active. The dead code needs to be kept in sync with the live version or it will drift further.
- **Recommendation:** Delete `confirmable.rb`. The behavior lives correctly in `Base#confirming`.

#### Finding: Dead code — LinkedCard model is never used

- **Severity:** Low
- **Location:** `lib/superthread/models/card.rb:245-256`
- **What:** `LinkedCard < Card` adds a single `linked_card_type` attribute but is never referenced outside its own file. The actual linked-card path uses `LinkedCardRef` via `Card#links`. A reader sees two parallel hierarchies (`LinkedCard < Card` and `LinkedCardRef < CardRef`) and has to work out which is live.
- **Why it matters:** `LinkedCard` looks authoritative because it's a proper Shale model inheriting the full 30-attribute weight of `Card`. The real path (`LinkedCardRef`) is less obvious. This is a readability trap.
- **Recommendation:** Delete `LinkedCard`. The `LinkedCardRef` pattern already handles the use case correctly.

#### Finding: LinkedCardRef#to_s overrides identical inherited method

- **Severity:** Low
- **Location:** `lib/superthread/models/card.rb:316-318` vs `287-289`
- **What:** `LinkedCardRef#to_s` returns `"#{title} (#{id})"` — character-for-character identical to `CardRef#to_s` which it inherits. The override is pure noise.
- **Why it matters:** A reader assumes the override is intentional and that it does something different.
- **Recommendation:** Remove the override.

#### Finding: Base includes 7 resolver concerns unconditionally

- **Severity:** Low
- **Location:** `lib/superthread/cli/base.rb:26-32`
- **What:** Every CLI subclass inherits all 7 resolver concerns (`WorkspaceResolvable`, `SpaceResolvable`, `BoardResolvable`, etc.) regardless of whether it uses them. Commands like `Accounts`, `Config`, and `Search` likely use none of them.
- **Why it matters:** At this project's scale this is not a practical problem — all concerns are lazy (private, called only on demand) so there's no runtime cost. Noted for completeness.
- **Recommendation:** No action needed at current scale. Revisit if a heavyweight concern with initialization cost is added.

### Coupling & Cohesion

**Health: Needs Attention**

#### Finding: Model references CLI layer constant (layer inversion)

- **Severity:** Medium
- **Location:** `lib/superthread/models/card.rb:201`, `lib/superthread/cli/formatter.rb:54-59`
- **What:** `Models::Card#priority_name` calls `Cli::Formatter::PRIORITY_LABELS` directly. The model layer has an upward dependency on the CLI layer. Any non-CLI consumer of `Models::Card` that calls `#priority_name` will pull in the entire `Cli::Formatter` module (which requires `active_support` and `unicode/display_width`).
- **Why it matters:** Models are the innermost layer; they should have zero knowledge of the CLI. This breaks the MVC principle and makes the model untestable in isolation without loading CLI infrastructure.
- **Recommendation:** Move `PRIORITY_LABELS` into the model layer — either directly on `Models::Card` as `PRIORITY_NAMES = {4=>"urgent", 3=>"high", 2=>"medium", 1=>"low"}.freeze` or in a small constants module. Have `Cli::Formatter` reference that shared constant instead. This reverses the dependency direction without changing behavior.

#### Finding: Dual object system with branching dispatch

- **Severity:** Medium
- **Location:** `lib/superthread/client.rb:127-151`, `lib/superthread/objects/collection.rb:156-168`
- **What:** The client and collection both carry an `if shale_model?` branch routing to either Shale deserialization or the legacy `Superthread::Object` hash wrapper. Several endpoints (`add_related`, `add_member`, `add_tags`, search) still return untyped `Object` instances.
- **Why it matters:** Every developer must understand two object protocols — the static Shale attribute API and the dynamic `method_missing` hash-key API. The branching dispatch is duplicated in two places (Client and Collection), and callers expecting typed models from untyped endpoints get silent surprises.
- **Recommendation:** Define minimal typed models for mutation endpoints (e.g., `Models::OperationResult`) and `Models::SearchResult` for search. Migrate incrementally until the `shale_model?` branches can be removed.

#### Finding: normalize_timestamp is a data utility living in the CLI layer

- **Severity:** Low
- **Location:** `lib/superthread/cli/formatter.rb:79-83`
- **What:** Pure data utility (converts millisecond timestamps to seconds) called from Cards CLI, Activity CLI, and the `DateParsable` concern — always via `Formatter` delegation.
- **Why it matters:** Same layer-inversion pattern as `PRIORITY_LABELS`. Any future resource or model needing timestamp normalization must depend on the CLI layer.
- **Recommendation:** Move to a `Superthread::TimeUtils` module or as a class method on `Superthread::Model`. Have Formatter delegate to it.

#### Finding: Dead code — workspace_path in Resources::Base

- **Severity:** Low
- **Location:** `lib/superthread/resources/base.rb:205-208`
- **What:** Defined but never called anywhere. Every resource builds workspace-prefixed paths inline using `safe_id` directly.
- **Why it matters:** Creates a false API surface — a future developer may use it believing it's the canonical pattern.
- **Recommendation:** Delete it.

### Framework Alignment

**Health: Good**

Thor is used correctly with subcommands, `class_options`, and `exit_on_failure?`. Faraday is used as a thin connection with no unnecessary middleware complexity. Shale is used declaratively as intended. Zeitwerk autoloading is correctly configured with `eager_load_namespace` for namespaces that need early registration. `ActiveSupport::Concern` is used properly for all mixins. No reinvented wheels detected.

### API & Interface Design

**Health: Good**

Resource interfaces are highly consistent: all take `workspace_id` as a first positional argument, additional IDs positionally, and named params for optional data. `compact_params` and `safe_id` helpers are uniformly applied. CLI output methods (`output_item`, `output_list`, `output_success`, `output_error`) provide a coherent output API. The `--json` flag is respected throughout.

### Duplication & Reuse

**Health: Needs Attention**

#### Finding: apply_date_filters duplicates DateParsable#filter_by_date

- **Severity:** Medium
- **Location:** `lib/superthread/cli/cards.rb:541-565`, `lib/superthread/cli/concerns/date_parsable.rb:103-113`
- **What:** Cards defines its own `apply_date_filters` and `meets_date_threshold?` private methods that replicate the same logic the already-included `DateParsable` concern provides via `filter_by_date` — iterate items, normalize timestamps, gate on a threshold.
- **Why it matters:** If timestamp normalization logic changes in `filter_by_date`, `apply_date_filters` silently diverges. The concern exists specifically to avoid this duplication.
- **Recommendation:** Delete both private methods from `cards.rb`. Replace with two chained `filter_by_date` calls: `cards = filter_by_date(cards, field: :time_created, since: parse_date(options[:since]))` and `cards = filter_by_date(cards, field: :time_updated, since: parse_date(options[:updated_since]))`.

#### Finding: Cards CLI uses inline begin/rescue instead of with_not_found

- **Severity:** Low
- **Location:** `lib/superthread/cli/cards.rb` (5 sites: lines 110-114, 228-274, 287-291, 311-318, 350)
- **What:** Cards has 5 sites using inline `begin/rescue` blocks to catch `ForbiddenError`/`NotFoundError`, while every other CLI class uses the `with_not_found` helper consistently.
- **Why it matters:** The inline pattern is noisier (4-5 lines vs 1 wrapper call) and creates inconsistency across the CLI layer.
- **Recommendation:** Replace each inline `begin/rescue` with `with_not_found` calls, following the `pages.rb` pattern.

#### Finding: resolve_list_with_context handles three dispatch paths inline

- **Severity:** Low
- **Location:** `lib/superthread/cli/cards.rb:503-539`
- **What:** 36-line method with three distinct dispatch paths: explicit context, sprint context, or board context. Each builds its result differently.
- **Why it matters:** Well-commented but dense. The sprint lookup path has non-obvious list matching logic (case-insensitive name match with ID fallback).
- **Recommendation:** Extract to three private methods: `resolve_list_with_explicit_context`, `resolve_list_in_sprint_context`, `resolve_list_on_board`. Do this when next touching the move feature.

## Prioritized Recommendations

### Quick Wins

1. **Delete dead code** — Remove `Confirmable` concern, `LinkedCard` model, `LinkedCardRef#to_s` override, and `workspace_path` helper. Four deletions, zero risk. (~30 minutes)
2. **Fix layer inversion for PRIORITY_LABELS** — Move the constant from `Cli::Formatter` to `Models::Card`. Update Formatter to reference the model constant. (~30 minutes)
3. **Replace apply_date_filters with DateParsable concern** — Delete the duplicate methods, use the existing concern. (~30 minutes)

### Medium Efforts

4. **Migrate Cards CLI to use with_not_found** — Replace 5 inline begin/rescue blocks with the helper, following pages.rb as the model. (~1-2 hours)
5. **Move normalize_timestamp to a shared utility** — Create `Superthread::TimeUtils` or add to `Model` base class. Update all call sites. (~1 hour)
6. **Extract resolve_list_with_context into three methods** — Readability improvement for the card move feature. (~1 hour)

### Strategic Restructuring

7. **Migrate remaining legacy Object endpoints to typed Shale models** — Define `Models::OperationResult`, `Models::SearchResult`, etc. Migrate `add_related`, `add_member`, `add_tags`, and search endpoints. Remove `shale_model?` branching from Client and Collection. (Multi-session effort, each endpoint is isolated)

## Action Plan

*Empty until decisions are made on which recommendations to pursue.*
