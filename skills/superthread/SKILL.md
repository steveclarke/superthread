---
name: superthread
description: Interact with Superthread project management via CLI. Use when creating/managing cards, viewing boards, searching tasks, or tracking work.
---

# Superthread CLI

Project management CLI for the Superthread API.

## Installation

```bash
brew install steveclarke/tap/superthread
```

## Setup

```bash
suth setup
```

The interactive wizard will:
1. Prompt for an account name (e.g., "personal" or "work")
2. Prompt for your API key (from Superthread Settings > API)
3. Validate and auto-detect your workspace
4. Save configuration

If prompts render incorrectly (e.g., in macOS Terminal.app), use plain mode:
```bash
SUPERTHREAD_PLAIN=1 suth setup
```

After setup, try:
```bash
suth spaces list
suth boards list -s SPACE
suth cards assigned me
```

## Global Options

```
-a, --account NAME    Use specific account for this command
-w, --workspace ID    Workspace (ID or name)
-y, --yes             Skip confirmation prompts (for scripts/agents)
-v, --verbose         Detailed logging
-q, --quiet           Minimal logging
--json                Output in JSON format (default is table)
--limit N             Max items to show (default: 50)
```

## Command Reference

### Accounts

```bash
suth accounts list                            # List all configured accounts
suth accounts show                            # Show current account details
suth accounts use NAME                        # Switch to account
suth accounts add NAME                        # Add new account (interactive)
suth accounts add NAME --with-token           # Non-interactive: read API key from stdin
suth accounts add NAME --workspace-name "X"   # Select workspace by name (non-interactive)
suth accounts remove NAME                     # Remove account
```

#### Non-interactive setup (for agents and scripts)

```bash
# Pipe API key from environment variable
echo "$SUPERTHREAD_API_KEY" | suth accounts add myaccount --with-token

# With specific workspace (when account has multiple)
echo "$SUPERTHREAD_API_KEY" | suth accounts add myaccount --with-token --workspace-name "My Team"
```

### Workspaces

```bash
suth workspaces list                          # List available workspaces
suth workspaces use WORKSPACE                 # Set default workspace
suth workspaces current                       # Show current workspace
```

### Current User & Members

```bash
suth me                                       # Get current user info
suth members list                             # List workspace members
```

### Spaces

```bash
suth spaces list                              # List all spaces
suth spaces get SPACE                         # Get space details
suth spaces create --title "Name"             # Create space
  # Options: --description, --icon NAME, --icon-color "#HEX"
suth spaces update SPACE --title "New Name"   # Update space
  # Options: --description, --icon NAME, --icon-color "#HEX"
suth spaces delete SPACE                      # Delete space
suth spaces add_member SPACE USERS [--role ROLE]  # Add member(s) (comma-separated)
suth spaces remove_member SPACE USERS         # Remove member(s) (comma-separated)
```

### Boards

```bash
suth boards list -s SPACE                     # List boards in space
  # Options: --bookmarked, --include-archived
suth boards get BOARD                         # Get board details
  # Options: -s SPACE (helps resolve board name)
suth boards create -s SPACE --title "Name"    # Create board
  # Options: --description, --layout (board|list|timeline|calendar),
  #          --icon NAME, --color COLOR
suth boards update BOARD --title "New Name"   # Update board
  # Options: -s SPACE, --description, --layout, --icon, --color, --archived
suth boards duplicate BOARD -s SPACE          # Duplicate board
  # Options: --title, --copy-cards, --create-missing-tags
suth boards delete BOARD                      # Delete board
  # Options: -s SPACE (helps resolve board name)
```

### Lists

Board list (column) management:

```bash
suth lists list -b BOARD                     # List columns on board
  # Options: -s SPACE (helps resolve board name)
suth lists create --title "In Progress" -b BOARD
  # Options: -s SPACE, --description, --icon NAME, --color COLOR
suth lists update LIST --title "Done"
  # Options: --description, --icon NAME, --color COLOR
suth lists delete LIST                       # Delete list
```

### Cards

```bash
# Listing
suth cards list -b BOARD                      # List cards on a board
suth cards list --sprint SPRINT -s SPACE      # List cards in a sprint
  # Options: --list, --include-archived, --since DATE, --updated-since DATE,
  #          -s SPACE (helps resolve board name)
suth cards assigned USER                      # Cards assigned to user
suth cards assigned me                        # Cards assigned to me
  # Options: --board, --space, --project, --include-archived,
  #          --since DATE, --updated-since DATE

# CRUD
suth cards get CARD                           # Get card details
  # Options: --raw, --no-content
suth cards create --title "Task" -l LIST -b BOARD [options]
  # Options: --content HTML, --project ID, --parent-card ID, --epic ID,
  #          --sprint SPRINT -s SPACE (alternative to --board),
  #          --start-date TIMESTAMP, --due-date TIMESTAMP,
  #          --priority N, --owner/-o USER
suth cards update CARD [options]
  # Options: --title, --list LIST, --board BOARD, --sprint SPRINT -s SPACE,
  #          --position N, --priority N, --epic ID, --archived/--no-archived
  # Note: list names auto-resolve for both board and sprint cards.
  #   Moving to a sprint requires --sprint and -s (space).
suth cards delete CARD                        # Delete card
suth cards duplicate CARD --project ID -b BOARD -l LIST
  # Required: --project, --board/-b, --list/-l
  # Options: --title, --space/-s (helps resolve board name)

# Members
suth cards assign CARD USERS                  # Assign user(s) (comma-separated)
suth cards unassign CARD USERS                # Unassign user(s) (comma-separated)

# Relationships
suth cards link --card CARD --related OTHER --type blocks
suth cards unlink --card CARD --related OTHER

# Tags
suth cards tag CARD tag1,tag2                 # Add tags
suth cards untag CARD tag1                    # Remove tag
```

### Projects (Epics)

```bash
suth projects list                            # List roadmap projects
suth projects get PROJECT                     # Get project details
suth projects create --title "Q1" -l LIST [-b BOARD]
  # Options: --content, --start-date TIMESTAMP, --due-date TIMESTAMP,
  #          --priority N, --owner/-o USER, -s SPACE (helps resolve board)
suth projects update PROJECT --title "New"
  # Options: --list/-l, --board/-b, --space/-s, --owner/-o USER,
  #          --start-date, --due-date, --priority, --archived
suth projects delete PROJECT
suth projects add_card PROJECT CARD           # Link card to project
suth projects remove_card PROJECT CARD        # Unlink card
```

### Pages

```bash
suth pages list [-s SPACE]                    # List pages
  # Options: --include-archived, --updated-recently
suth pages get PAGE                           # Get page details
suth pages create -s SPACE [--title "Doc"]    # Create page
  # Options: --content, --parent-page ID, --is-public
suth pages update PAGE --title "New title"    # Update page
  # Options: --is-public, --parent-page ID, --archived
suth pages duplicate PAGE -s SPACE            # Duplicate page
  # Options: --title, --parent-page ID
suth pages archive PAGE                       # Archive page
suth pages delete PAGE                        # Delete page
```

### Comments

```bash
suth comments list -c CARD                   # List comments on a card
suth comments get COMMENT                    # Get comment details
suth comments create --content "Note" -c CARD
  # Options: --page/-p PAGE (use instead of --card for page comments)
suth comments update COMMENT --content "Updated"
  # Options: --status (resolved|open|orphaned)
suth comments delete COMMENT
```

### Replies

```bash
suth replies list --comment COMMENT                     # List replies to a comment
suth replies get REPLY --comment COMMENT                # Get reply details
suth replies create --comment COMMENT --content "Reply text"
suth replies update REPLY --comment COMMENT --content "Updated"
  # Options: --status (resolved|open|orphaned)
suth replies delete REPLY --comment COMMENT
```

### Checklists

Checklists are a separate subcommand, not under `cards`:

```bash
suth checklists list -c CARD                 # List checklists on a card
suth checklists get CHECKLIST -c CARD        # Get checklist details
suth checklists create --title "Tasks" -c CARD
suth checklists update CHECKLIST --title "New Title" -c CARD
suth checklists delete CHECKLIST -c CARD

# Items
suth checklists add-item CHECKLIST --title "Do thing" -c CARD [--checked]
suth checklists update-item ITEM --checklist CL -c CARD --title "New"
suth checklists remove-item ITEM --checklist CL -c CARD
suth checklists check ITEM --checklist CL -c CARD
suth checklists uncheck ITEM --checklist CL -c CARD
```

### Tags

```bash
suth tags list                               # List available tags
  # Options: --space/-s SPACE, --all (include unused tags)
suth tags create --name "urgent" --color "#ff0000"
  # Options: --space/-s SPACE
suth tags update TAG --name "critical"
  # Options: --color
suth tags delete TAG
```

### Notes

```bash
suth notes list                               # List notes
suth notes get NOTE                           # Get note details
suth notes create --title "Meeting" [--transcript "..."]
  # Options: --user-notes, --is-public
suth notes delete NOTE
```

### Sprints

```bash
suth sprints list -s SPACE                    # List sprints in space
suth sprints get SPRINT -s SPACE              # Get sprint details
```

### Search

```bash
suth search query "term"                      # Search workspace
suth search query "bug" --types card,page     # Filter by type
suth search query "auth" -s SPACE [--grouped] # Filter by space
  # Options: --field (title|content), --include-archived
```

### Config

```bash
suth config init                              # Create default config file
suth config show                              # Show current configuration
suth config set KEY VALUE                     # Set a config value
suth config path                              # Show config file path
```

### Activity

```bash
suth activity                                 # Show recent activity (default: today)
  # `activity` runs the `show` subcommand by default
  # Options: --since DATE (e.g., "friday", "3 days ago"),
  #          --user USER, --board/-b BOARD, --space/-s SPACE
```

### Shell Completion

```bash
suth completion bash                          # Generate bash completion script
suth completion zsh                           # Generate zsh completion script
suth completion fish                          # Generate fish completion script
```

## Option Aliases

| Long | Short | Description |
|------|-------|-------------|
| `--space` | `-s` | Space (ID or name) |
| `--board` | `-b` | Board (ID or name) |
| `--list` | `-l` | List (ID or name) |
| `--card` | `-c` | Card ID |
| `--related` | `-r` | Related card ID |
| `--owner` | `-o` | Owner (user ID, name, or email) |
| `--yes` | `-y` | Skip confirmation prompts |

## Tips

- Most commands accept **names or IDs** for spaces, boards, lists, sprints, users, and tags
- Use `-s SPACE` to help resolve ambiguous board/list/sprint names
- Use `--json` for scripted output: `suth cards assigned me --json`
- Use `me` as a user reference: `suth cards assigned me`
- Use `-y` to skip confirmation prompts (for scripts/agents)
- Priority levels: 1=Urgent, 2=High, 3=Medium, 4=Low
- Sprint cards auto-detect context: `suth cards update CARD -l "Done"` works without `--sprint`
