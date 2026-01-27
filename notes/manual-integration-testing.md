# Manual Integration Testing Plan

This document walks through manual integration testing of the Superthread CLI (`suth`) against a live SuperThread account. Each section tests a command group with all its subcommands and options.

**Testing approach:**
1. Run the command in the terminal
2. Inspect the output for correctness and UX issues
3. Verify in the SuperThread web app where applicable
4. Note any issues discovered

**Legend:**
- [ ] Not tested
- [x] Tested - OK
- [!] Tested - Issue found (see notes)

---

## Prerequisites

Before starting, ensure:
- [x] `suth` CLI is installed and configured
- [x] Run `suth config show` to verify your account is set up
- [x] Note your workspace ID for reference

**Testing Session:**
- Date: 2026-01-24
- Account: Personal (Clevertakes)
- Workspace: t5kahi36

---

## 1. CONFIG

### 1.1 config show
Display current configuration.

```bash
suth config show
```

**Check:**
- [x] Config file path displayed correctly
- [x] State file path displayed correctly
- [x] Current account shown with asterisk
- [x] API key partially masked
- [x] Workspace displayed
- [x] All accounts listed

**Notes:** All output clear and well-formatted. Accounts aligned properly with asterisk marker.


### 1.2 config path
Show just the config file path.

```bash
suth config path
```

**Check:**
- [x] Path is displayed (e.g., `~/.config/superthread/config.yaml`)

**Notes:** Clean output, just the path with no extra text.


### 1.3 config init
Create a new config file (skip if already exists).

```bash
suth config init
```

**Check:**
- [ ] Creates config file if missing (not tested - file exists)
- [x] Shows warning if file already exists
- [ ] Suggests running `suth setup` (not shown when file exists)

**Notes:** Warning message shown: "Config file already exists at /Users/steve/.config/superthread/config.yaml"


### 1.4 config set
Set configuration values.

```bash
# Test valid format setting
suth config set format json
suth config show   # verify it changed

# Switch back
suth config set format table
suth config show   # verify it changed

# Test invalid key
suth config set invalid_key value

# Test invalid format value
suth config set format invalid
```

**Check:**
- [x] Setting format to json works
- [x] Setting format to table works
- [x] Invalid key shows helpful error
- [x] Invalid format value shows helpful error

**Notes:**
- Success: "Set format = json"
- Invalid key error: "Unknown config key: foo. Valid keys: format, base_url"
- Invalid format error: "Invalid format: tables. Valid values: json, table"
- All error messages are clear and actionable.


---

## 2. SPACES

### 2.1 spaces list
List all spaces in the workspace.

```bash
suth spaces list
suth spaces list --json
```

**Check:**
- [x] Shows table with ID and Title columns
- [x] JSON output is valid JSON
- [x] All spaces from web app are listed

**Notes:**
- Table output clean
- JSON valid but `icon` field contains Ruby hash syntax instead of JSON (e.g., `{\"color\" => \"#7F56D9\"...}`)


### 2.2 spaces get
Get details of a specific space.

```bash
# By ID (use an ID from the list above)
suth spaces get SPACE_ID

# By name
suth spaces get "Space Name"

# With --open flag (opens in browser)
suth spaces get SPACE_ID --open

# With JSON output
suth spaces get SPACE_ID --json
```

**Check:**
- [x] Displays: id, title, description, time_created, time_updated
- [!] Name resolution works
- [x] Browser opens correct URL with --open
- [x] JSON output is valid

**Notes:**
- **BUG:** Name resolution returns 403 error instead of resolving name to ID
- By ID works fine
- --open works, shows "Opened in browser: https://app.superthread.com/..."


### 2.3 spaces create
Create a new space.

```bash
suth spaces create --title "CLI Test Space"
suth spaces create --title "CLI Test Space 2" --description "Created via CLI" --icon "rocket"
```

**Check:**
- [x] Space created successfully
- [x] Verify in SuperThread web app
- [!] Description and icon applied correctly

**Notes:**
- Title + description works
- **BUG:** `--icon` fails with "HTTP 400: json: cannot unmarshal string into Go struct field CreateProjectRequest.icon of type models.Image"
- Icon expects an Image object, not a string


### 2.4 spaces update
Update an existing space.

```bash
# Update title
suth spaces update "CLI Test Space" --title "CLI Test Space Updated"

# Update description
suth spaces update "CLI Test Space Updated" --description "Updated description"
```

**Check:**
- [x] Title update works
- [x] Description update works

**Notes:**
- Title and description updates work fine
- `--archived` option removed - Superthread API doesn't support archiving spaces


### 2.5 spaces add_member / remove_member
Manage space membership.

```bash
# Add a member (use a valid user ID/email from your workspace)
suth spaces add_member "CLI Test Space" USER_REF

# Add with role
suth spaces add_member "CLI Test Space" USER_REF --role admin

# Remove member
suth spaces remove_member "CLI Test Space" USER_REF
```

**Check:**
- [ ] Add member works (skipped - single user workspace)
- [ ] Role assignment works (skipped)
- [ ] Remove member works (skipped)
- [ ] Verify membership changes in web app (skipped)

**Notes:** Skipped - only one user in workspace.


### 2.6 spaces delete
Delete a space.

```bash
# With confirmation prompt
suth spaces delete "CLI Test Space Updated"

# With skip confirmation
suth spaces delete "CLI Test Space 2" --skip-confirm
```

**Check:**
- [x] Confirmation prompt appears
- [ ] Can cancel with 'n' (not tested)
- [x] Can confirm with 'y'
- [x] --skip-confirm bypasses prompt
- [x] Space actually deleted (verify in web app)

**Notes:** Confirmation and delete both work correctly.


---

## 3. BOARDS

### 3.1 boards list
List boards in a space.

```bash
# Basic list (requires space)
suth boards list -s "Space Name"

# By space ID
suth boards list -s SPACE_ID

# Filter by bookmarked
suth boards list -s "Space Name" --bookmarked

# Include archived
suth boards list -s "Space Name" --archived

# JSON output
suth boards list -s "Space Name" --json
```

**Check:**
- [x] Shows table with ID and Title columns
- [!] Space name resolution works
- [x] Space ID works
- [ ] --bookmarked filter works (not tested)
- [ ] --archived filter works (not tested)
- [ ] JSON output is valid (not tested)

**Notes:** Space name resolution fails with 403 (same root issue as spaces - Issue #2)


### 3.2 boards get
Get board details.

```bash
# By ID
suth boards get BOARD_ID

# By name (with space hint)
suth boards get "Board Name" -s "Space Name"

# With --open
suth boards get BOARD_ID --open

# JSON output
suth boards get BOARD_ID --json
```

**Check:**
- [x] Displays: id, title, time_created, time_updated
- [ ] Name resolution works (not tested)
- [!] Browser opens correct URL
- [ ] JSON output is valid (not tested)

**Notes:** --open generates URL `/t5kahi36/boards/4` which gives "There's been a glitch" error. URL format may be wrong (needs verification with correct browser session).


### 3.3 boards lists
List columns/lists on a board.

```bash
suth boards lists BOARD_ID
suth boards lists "Board Name" -s "Space Name"
suth boards lists BOARD_ID --json
```

**Check:**
- [x] Shows table with ID, Title, Color columns
- [ ] Board name resolution works (not tested)
- [ ] JSON output is valid (not tested)
- [ ] Message if no lists found (not tested)

**Notes:** Lists displayed correctly with colors.


### 3.4 boards create
Create a new board.

```bash
# Minimal
suth boards create -s "Space Name" --title "CLI Test Board"

# With all options
suth boards create -s "Space Name" --title "CLI Test Board Full" \
  --description "Created via CLI" \
  --layout board \
  --icon rocket \
  --color blue
```

**Check:**
- [x] Board created successfully
- [ ] Verify in SuperThread web app (not verified)
- [ ] Layout applies correctly (not verified in web app)
- [ ] Icon applies correctly (not tested)
- [ ] Color applies correctly (not verified in web app)

**Notes:** Basic create works. Options like layout/color not visible in API response - need web app verification.


### 3.5 boards update
Update a board.

```bash
suth boards update BOARD_ID --title "Updated Title"
suth boards update BOARD_ID --description "Updated description"
suth boards update BOARD_ID --layout timeline
suth boards update BOARD_ID --color green
suth boards update BOARD_ID --archived
suth boards update BOARD_ID --no-archived
```

**Check:**
- [x] Title update works
- [ ] Description update works (not tested)
- [ ] Layout change works (not tested)
- [ ] Color change works (not tested)
- [ ] Archive/unarchive works (not tested)

**Notes:** Title update confirmed working.


### 3.6 boards duplicate
Duplicate a board.

```bash
# Basic duplicate
suth boards duplicate BOARD_ID -s "Space Name"

# With custom title
suth boards duplicate BOARD_ID -s "Space Name" --title "Duplicated Board"

# With cards
suth boards duplicate BOARD_ID -s "Space Name" --copy-cards

# With tags
suth boards duplicate BOARD_ID -s "Space Name" --copy-cards --create-missing-tags
```

**Check:**
- [x] Basic duplicate works
- [x] Custom title applied
- [ ] Cards copied when --copy-cards specified (not tested)
- [ ] Tags created when --create-missing-tags specified (not tested)

**Notes:** Duplicate works - copies lists with colors.


### 3.7 boards create-list
Create a list/column on a board.

```bash
suth boards create-list -b BOARD_ID --title "New List"
suth boards create-list -b "Board Name" -s "Space Name" --title "Styled List" \
  --description "List description" \
  --color green \
  --icon checkmark
```

**Check:**
- [x] List created on correct board
- [ ] Description applied (not tested)
- [x] Color applied
- [ ] Icon applied (not tested)
- [ ] Verify in web app (not verified)

**Notes:** Create-list works with title and color.


### 3.8 boards update-list
Update a list.

```bash
suth boards update-list LIST_ID --title "Renamed List"
suth boards update-list LIST_ID --color red
```

**Check:**
- [x] Title update works
- [x] Color update works

**Notes:** Both title and color updates work.


### 3.9 boards delete-list
Delete a list.

```bash
suth boards delete-list LIST_ID
suth boards delete-list LIST_ID --skip-confirm
```

**Check:**
- [x] Confirmation prompt appears
- [x] List deleted successfully

**Notes:** Confirmation and delete work correctly.


### 3.10 boards delete
Delete a board.

```bash
suth boards delete BOARD_ID
suth boards delete "Board Name" -s "Space Name" --skip-confirm
```

**Check:**
- [x] Confirmation shows board title and ID
- [x] Board deleted successfully

**Notes:** Confirmation prompt shows board title, deletion works.


---

## 4. CARDS

### 4.1 cards list
List cards on a board.

```bash
suth cards list -b BOARD_ID
suth cards list -b "Board Name" -s "Space Name"
suth cards list -b BOARD_ID -l "List Name"
suth cards list -b BOARD_ID --archived
suth cards list -b BOARD_ID --json
```

**Check:**
- [ ] Shows table with ID, Title, Priority, List columns
- [ ] Board name resolution works
- [ ] List filter works
- [ ] --archived filter works
- [ ] JSON output is valid

**Notes:**


### 4.2 cards get
Get card details.

```bash
suth cards get CARD_ID
suth cards get CARD_ID --raw        # Raw content (no markdown)
suth cards get CARD_ID --no-content # Hide content
suth cards get CARD_ID --open       # Open in browser
suth cards get CARD_ID --json
```

**Check:**
- [ ] Displays metadata fields correctly
- [ ] Content rendered with markdown by default
- [ ] --raw shows unrendered content
- [ ] --no-content hides content section
- [ ] Browser opens correct URL
- [ ] JSON output is valid

**Notes:**


### 4.3 cards create
Create a new card.

```bash
# Minimal
suth cards create --title "CLI Test Card" -l "To Do" -b BOARD_ID

# With all options
suth cards create --title "CLI Full Card" -l "To Do" -b BOARD_ID \
  --content "Card description" \
  --priority 2 \
  --owner "user@email.com"
```

**Check:**
- [ ] Card created successfully
- [ ] Content applied
- [ ] Priority applied (1=urgent, 4=low)
- [ ] Owner assigned
- [ ] Verify in web app

**Notes:**


### 4.4 cards update
Update a card.

```bash
suth cards update CARD_ID --title "Updated Title"
suth cards update CARD_ID --priority 1
suth cards update CARD_ID -l "Done" -b BOARD_ID  # Move to different list
suth cards update CARD_ID --archived
suth cards update CARD_ID --no-archived
```

**Check:**
- [ ] Title update works
- [ ] Priority update works
- [ ] Moving to different list works
- [ ] Archive/unarchive works

**Notes:**


### 4.5 cards duplicate
Duplicate a card.

```bash
suth cards duplicate CARD_ID
suth cards duplicate CARD_ID --title "Copied Card"
```

**Check:**
- [ ] Card duplicated successfully
- [ ] Custom title applied when specified

**Notes:**


### 4.6 cards assigned
Get cards assigned to a user.

```bash
suth cards assigned USER_REF
suth cards assigned USER_REF -b BOARD_ID
suth cards assigned USER_REF --project PROJECT_ID
suth cards assigned USER_REF --archived
```

**Check:**
- [ ] Lists cards assigned to user
- [ ] Board filter works
- [ ] Project filter works
- [ ] Archived filter works

**Notes:**


### 4.7 cards assign / unassign
Manage card assignments.

```bash
suth cards assign CARD_ID USER_REF
suth cards assign CARD_ID USER_REF --role member
suth cards unassign CARD_ID USER_REF
```

**Check:**
- [ ] Assign works
- [ ] Role assignment works
- [ ] Unassign works
- [ ] Verify assignments in web app

**Notes:**


### 4.8 cards link / unlink
Manage card relationships.

```bash
# Link cards
suth cards link CARD_ID OTHER_CARD_ID --type blocks
suth cards link CARD_ID OTHER_CARD_ID --type blocked_by
suth cards link CARD_ID OTHER_CARD_ID --type related
suth cards link CARD_ID OTHER_CARD_ID --type duplicates

# Unlink
suth cards unlink CARD_ID OTHER_CARD_ID
```

**Check:**
- [ ] blocks relationship works
- [ ] blocked_by relationship works
- [ ] related relationship works
- [ ] duplicates relationship works
- [ ] Unlink works
- [ ] Verify relationships in web app

**Notes:**


### 4.9 cards add-checklist / edit-checklist / remove-checklist
Manage checklists. Checklists are displayed in `cards get` output.

```bash
# View checklists on a card
suth cards get CARD_ID

# Create a checklist
suth cards add-checklist CARD_ID --title "Test Checklist"
# Note the checklist ID from output

# Edit checklist title
suth cards edit-checklist -c CARD_ID --checklist CHECKLIST_ID --title "Renamed Checklist"

# Delete checklist
suth cards remove-checklist -c CARD_ID --checklist CHECKLIST_ID
```

**Check:**
- [ ] Checklists displayed in `cards get` with progress (e.g., "2/5")
- [ ] Checklist items shown with ✓/○ markers
- [ ] Checklist created
- [ ] Checklist renamed
- [ ] Checklist deleted
- [ ] Confirmation prompt for delete

**Notes:**


### 4.10 cards add-item / edit-item / remove-item
Manage checklist items.

```bash
# Add items to checklist
suth cards add-item -c CARD_ID --checklist CHECKLIST_ID --title "Item 1"
suth cards add-item -c CARD_ID --checklist CHECKLIST_ID --title "Item 2 (checked)" --checked
# Note the item ID from output

# Edit item (title or checked state)
suth cards edit-item -c CARD_ID --checklist CHECKLIST_ID --item ITEM_ID --title "Renamed item"
suth cards edit-item -c CARD_ID --checklist CHECKLIST_ID --item ITEM_ID --checked
suth cards edit-item -c CARD_ID --checklist CHECKLIST_ID --item ITEM_ID --no-checked

# Delete item
suth cards remove-item -c CARD_ID --checklist CHECKLIST_ID --item ITEM_ID
```

**Check:**
- [ ] Item created unchecked by default
- [ ] Item created checked with --checked
- [ ] Item renamed
- [ ] Item checked/unchecked
- [ ] Item deleted

**Notes:**


### 4.11 cards tag / untag
Add and remove tags from cards.

```bash
# Add tags to card
suth cards tag CARD_ID "tag-name"
suth cards tag CARD_ID "tag1,tag2,tag3"

# Remove tag
suth cards untag CARD_ID "tag-name"
```

**Check:**
- [ ] Tag by name works
- [ ] Multiple tags (comma-separated) works
- [ ] Untag works

**Notes:**


### 4.12 cards delete
Delete a card.

```bash
suth cards delete CARD_ID
suth cards delete CARD_ID --skip-confirm
```

**Check:**
- [ ] Confirmation shows card title
- [ ] Card deleted successfully

**Notes:**


---

## 5. COMMENTS

### 5.1 comments get
Get comment details.

```bash
suth comments get COMMENT_ID
suth comments get COMMENT_ID --open
suth comments get COMMENT_ID --json
```

**Check:**
- [ ] Displays: id, content, user_id, card_id, timestamps
- [ ] --open opens the parent card
- [ ] JSON output is valid

**Notes:**


### 5.2 comments create
Create a comment.

```bash
suth comments create --content "Test comment" --card_id CARD_ID
suth comments create --content "Page comment" --page_id PAGE_ID
```

**Check:**
- [ ] Comment on card works
- [ ] Comment on page works
- [ ] Verify in web app

**Notes:**


### 5.3 comments update
Update a comment.

```bash
suth comments update COMMENT_ID --content "Updated content"
suth comments update COMMENT_ID --status resolved
suth comments update COMMENT_ID --status open
```

**Check:**
- [ ] Content update works
- [ ] Status change to resolved works
- [ ] Status change to open works

**Notes:**


### 5.4 comments reply / replies
Comment threads.

```bash
suth comments reply COMMENT_ID --content "This is a reply"
suth comments replies COMMENT_ID
```

**Check:**
- [ ] Reply created
- [ ] Replies listed correctly

**Notes:**


### 5.5 comments update_reply / delete_reply
Manage replies.

```bash
suth comments update_reply COMMENT_ID REPLY_ID --content "Updated reply"
suth comments delete_reply COMMENT_ID REPLY_ID
```

**Check:**
- [ ] Reply content updated
- [ ] Reply deleted with confirmation

**Notes:**


### 5.6 comments delete
Delete a comment.

```bash
suth comments delete COMMENT_ID
```

**Check:**
- [ ] Confirmation shows truncated content
- [ ] Comment deleted

**Notes:**


---

## 6. NOTES

### 6.1 notes list
List all notes.

```bash
suth notes list
suth notes list --json
```

**Check:**
- [ ] Shows table with ID, Title, time_created
- [ ] JSON output is valid

**Notes:**


### 6.2 notes get
Get note details.

```bash
suth notes get NOTE_ID
suth notes get NOTE_ID --open
suth notes get NOTE_ID --json
```

**Check:**
- [ ] Displays: id, title, content, timestamps
- [ ] Browser opens correct URL
- [ ] JSON output is valid

**Notes:**


### 6.3 notes create
Create a note.

```bash
suth notes create --title "CLI Test Note"
suth notes create --title "Full Note" --transcript "Some transcript" --user_notes "My notes" --is_public
```

**Check:**
- [ ] Note created with title only
- [ ] Transcript applied
- [ ] User notes applied
- [ ] Public flag applied
- [ ] Verify in web app

**Notes:**


### 6.4 notes delete
Delete a note.

```bash
suth notes delete NOTE_ID
suth notes delete NOTE_ID --skip-confirm
```

**Check:**
- [ ] Confirmation shows note title
- [ ] Note deleted

**Notes:**


---

## 7. PAGES

### 7.1 pages list
List all pages.

```bash
suth pages list
suth pages list -s "Space Name"
suth pages list --archived
suth pages list --updated_recently
suth pages list --json
```

**Check:**
- [ ] Shows table with ID, Title, space_id
- [ ] Space filter works
- [ ] Archived filter works
- [ ] Updated recently filter works
- [ ] JSON output is valid

**Notes:**


### 7.2 pages get
Get page details.

```bash
suth pages get PAGE_ID
suth pages get PAGE_ID --open
suth pages get PAGE_ID --json
```

**Check:**
- [ ] Displays: id, title, space_id, timestamps
- [ ] Browser opens correct URL
- [ ] JSON output is valid

**Notes:**


### 7.3 pages create
Create a page.

```bash
suth pages create -s "Space Name" --title "CLI Test Page"
suth pages create -s "Space Name" --title "Full Page" --content "Page content" --is_public
suth pages create -s "Space Name" --title "Child Page" --parent_page PARENT_PAGE_ID
```

**Check:**
- [ ] Page created with title
- [ ] Content applied
- [ ] Public flag applied
- [ ] Parent page relationship works
- [ ] Verify in web app

**Notes:**


### 7.4 pages update
Update a page.

```bash
suth pages update PAGE_ID --title "Updated Title"
suth pages update PAGE_ID --is_public
suth pages update PAGE_ID --parent_page OTHER_PAGE_ID
suth pages update PAGE_ID --archived
```

**Check:**
- [ ] Title update works
- [ ] Public flag works
- [ ] Moving under different parent works
- [ ] Archive works

**Notes:**


### 7.5 pages duplicate
Duplicate a page.

```bash
suth pages duplicate PAGE_ID -s "Space Name"
suth pages duplicate PAGE_ID -s "Space Name" --title "Copied Page"
suth pages duplicate PAGE_ID -s "Space Name" --parent_page PARENT_ID
```

**Check:**
- [ ] Page duplicated
- [ ] Custom title applied
- [ ] Parent assignment works

**Notes:**


### 7.6 pages archive
Archive a page (convenience command).

```bash
suth pages archive PAGE_ID
```

**Check:**
- [ ] Page archived
- [ ] Verify in web app

**Notes:**


### 7.7 pages delete
Delete a page permanently.

```bash
suth pages delete PAGE_ID
suth pages delete PAGE_ID --skip-confirm
```

**Check:**
- [ ] Confirmation shows page title
- [ ] Page deleted permanently

**Notes:**


---

## 8. PROJECTS

### 8.1 projects list
List all roadmap projects.

```bash
suth projects list
suth projects list --json
```

**Check:**
- [ ] Shows table with ID, Title, Status
- [ ] JSON output is valid

**Notes:**


### 8.2 projects get
Get project details.

```bash
suth projects get PROJECT_ID
suth projects get PROJECT_ID --open
suth projects get PROJECT_ID --json
```

**Check:**
- [ ] Displays: id, title, status, dates, timestamps
- [ ] Browser opens correct URL
- [ ] JSON output is valid

**Notes:**


### 8.3 projects create
Create a project.

```bash
suth projects create --title "CLI Test Project" -l "To Do" -b BOARD_ID
suth projects create --title "Full Project" -l "To Do" -b BOARD_ID \
  --content "Project description" \
  --start_date 1700000000 \
  --due_date 1710000000 \
  --owner "user@email.com" \
  --priority 2
```

**Check:**
- [ ] Project created with required fields
- [ ] Content applied
- [ ] Dates applied
- [ ] Owner assigned
- [ ] Priority applied
- [ ] Verify in web app

**Notes:**


### 8.4 projects update
Update a project.

```bash
suth projects update PROJECT_ID --title "Updated Project"
suth projects update PROJECT_ID -l "Done" -b BOARD_ID  # Move to list
suth projects update PROJECT_ID --owner "other@email.com"
suth projects update PROJECT_ID --priority 1
suth projects update PROJECT_ID --archived
```

**Check:**
- [ ] Title update works
- [ ] Moving to different list works
- [ ] Owner change works
- [ ] Priority change works
- [ ] Archive works

**Notes:**


### 8.5 projects add_card / remove_card
Link cards to projects.

```bash
suth projects add_card PROJECT_ID CARD_ID
suth projects remove_card PROJECT_ID CARD_ID
```

**Check:**
- [ ] Card linked to project
- [ ] Card unlinked from project
- [ ] Verify in web app

**Notes:**


### 8.6 projects delete
Delete a project.

```bash
suth projects delete PROJECT_ID
suth projects delete PROJECT_ID --skip-confirm
```

**Check:**
- [ ] Confirmation shows project title
- [ ] Project deleted

**Notes:**


---

## 9. TAGS

### 9.0 tags list
List available tags.

```bash
suth tags list
suth tags list --all
suth tags list -s SPACE
```

**Check:**
- [ ] Tags listed with ID, name, color, total_cards
- [ ] --all shows all tags including unused
- [ ] -s SPACE filters by space

**Notes:**


### 9.1 tags create
Create a tag.

```bash
suth tags create --name "CLI Tag" --color "#FF5733"
suth tags create --name "Space Tag" --color "#33FF57" -s "Space Name"
```

**Check:**
- [ ] Tag created with name and color
- [ ] Space-scoped tag created
- [ ] Verify in web app

**Notes:**


### 9.2 tags update
Update a tag.

```bash
suth tags update "CLI Tag" --name "Renamed Tag"
suth tags update "Renamed Tag" --color "#3357FF"
```

**Check:**
- [ ] Name change works
- [ ] Color change works

**Notes:**


### 9.3 tags delete
Delete a tag.

```bash
suth tags delete "Renamed Tag"
suth tags delete TAG_ID --skip-confirm
```

**Check:**
- [ ] Confirmation shows tag name
- [ ] Tag deleted

**Notes:**


---

## 10. SEARCH

### 10.1 search query
Search across workspace.

```bash
# Basic search
suth search query "test"

# Search specific field
suth search query "test" --field title
suth search query "test" --field content

# Filter by types
suth search query "test" --types card
suth search query "test" --types "card,page,board"

# Filter by space
suth search query "test" -s "Space Name"

# Include archived
suth search query "test" --archived

# Group results
suth search query "test" --grouped

# JSON output
suth search query "test" --json
```

**Check:**
- [ ] Basic search returns results
- [ ] Field filter works (title/content)
- [ ] Type filter works (single type)
- [ ] Type filter works (multiple types)
- [ ] Space filter works
- [ ] Archived filter works
- [ ] Grouped output works
- [ ] JSON output is valid

**Notes:**


---

## 11. COMPLETION

### 11.1 completion bash
Generate bash completion script.

```bash
suth completion bash
```

**Check:**
- [ ] Script generated without errors
- [ ] Script looks valid (starts with comments, has _suth function)

**Notes:**


### 11.2 completion zsh
Generate zsh completion script.

```bash
suth completion zsh
```

**Check:**
- [ ] Script generated without errors
- [ ] Script starts with #compdef suth

**Notes:**


### 11.3 completion fish
Generate fish completion script.

```bash
suth completion fish
```

**Check:**
- [ ] Script generated without errors
- [ ] Script has proper fish completion format

**Notes:**


---

## Global Options Testing

Test these global options with various commands:

```bash
# Verbose output
suth spaces list --verbose

# Quiet output
suth spaces list --quiet

# JSON output
suth spaces list --json

# Different account
suth spaces list --account work

# Workspace override
suth spaces list --workspace OTHER_WORKSPACE_ID

# Skip confirmation
suth spaces delete "Test Space" --skip-confirm
```

**Check:**
- [ ] --verbose shows more detail
- [ ] --quiet shows minimal output
- [ ] --json works on all list/get commands
- [ ] --account switches accounts
- [ ] --workspace overrides default workspace
- [ ] --skip-confirm bypasses confirmation prompts

---

## Issues Log

| # | Command | Issue Description | Severity | Status |
|---|---------|-------------------|----------|--------|
| 1 | `spaces list --json` | `icon` field contains Ruby hash syntax instead of JSON | Low | Open |
| 2 | `spaces get NAME` | Name resolution returns 403 instead of resolving to ID | Medium | Fixed |
| 3 | `spaces create --icon` | `--icon` expects Image object, fails with string | Medium | Fixed |
| 4 | `spaces update --archived` | API doesn't support archiving spaces - option removed | Medium | Removed |
| 5 | `boards get --open` | URL format `/workspace/boards/ID` gives glitch error (needs verification) | Low | Open |
| 6 | `cards update` | Title ignored when combined with list move (`--title` + `-l`) | Medium | Fixed |
| 7 | `cards duplicate` | Fails - API requires `project_id` but no option exists | High | Fixed |
| 8 | `cards add-checklist` | Response shows all "-" - data saved but not returned properly | Medium | Fixed |
| 9 | `cards add-item` | Response shows all "-" - data saved but not returned properly | Medium | Fixed |
| 10 | `cards tag NAME` | Tag by name fails (404), but tag by ID works - name resolution broken | Medium | Fixed |
| 11 | UX: Multiple commands | Positional numeric IDs are confusing - should use named options (--card, --checklist, etc.) | Medium | Open |
| 12 | UX: Multiple commands | Consider comma-separated values for bulk operations (tags, members) | Low | Open |
| 13 | `comments create` | Uses `--card_id` instead of `--card` (inconsistent with other commands) | Low | Open |
| 14 | `comments reply` | Wrong API endpoint: uses `/comments` instead of `/children` - returns 404 | High | Fixed |
| 15 | `comments replies` | Wrong API endpoint + wrong key (`comments` → `child_comments`) | High | Fixed |
| 16 | Feature: comments, checklists | Port `{{@Username}}` mention syntax and HTML formatting from MCP server (applies to comments, replies, and checklist item titles) | Medium | Open |
| 17 | `pages get/create` | Shows "Space id: -" but API doesn't return space_id - either remove field or populate it | Medium | Open |
| 18 | `pages list` | Returns empty without `-s` filter even when pages exist | Medium | Open |
| 19 | `projects list` | Returns empty even when projects exist (similar to pages issue) | Medium | Open |
| 20 | `search query` | Wrong param name: uses `q` but API expects `query` - returns 400 | High | Fixed |
| 21 | `search query` | Search returns no results even with valid terms - needs investigation | High | Fixed |
