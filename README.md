# Superthread

Ruby gem and CLI for [Superthread](https://superthread.com) project management.

> [!WARNING]
> **Pre-Release Software**
>
> This is a community-maintained project and is **not officially affiliated with or endorsed by Superthread**. It is a work in progress and not yet production-ready.
>
> We built this to provide comprehensive CLI and library access to the Superthread API for our own workflows. While we use it daily, it may have bugs, breaking changes, or incomplete features.
>
> **Use at your own risk.** Test thoroughly in non-critical environments before relying on it for important workflows. Issues and pull requests are welcome, but support is limited.

## Installation

### Homebrew (recommended)

```bash
brew install steveclarke/tap/superthread
```

### RubyGems

```bash
gem install superthread
```

Or add to your Gemfile:

```ruby
gem "superthread"
```

## Configuration

### Config File

Create `~/.config/superthread/config.yaml`:

```yaml
# API key (required) - get from Superthread settings
api_key: stp_xxxxxxxxxxxx

# Output format: json or table
format: json

# Workspace aliases for quick switching
workspaces:
  personal: ws_abc123
  work: ws_def456
```

### Quick Setup

Run the interactive setup wizard:

```bash
suth setup
```

The wizard will:
1. Prompt for your API key (from Superthread Settings → API)
2. Validate and fetch your workspaces
3. Let you select a default workspace
4. Save configuration

After setup, try:
```bash
suth spaces list
suth boards list -s SPACE
suth cards assigned me
```

Or initialize a blank config file manually:

```bash
suth config init
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPERTHREAD_API_KEY` | API key (overrides config file) |
| `SUPERTHREAD_WORKSPACE_ID` | Default workspace ID |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: `https://api.superthread.com/v1`) |

## CLI Usage

The CLI is available as `suth`.

### Global Options

```
-w, --workspace ID    Workspace ID (or use config/env var)
-v, --verbose         Detailed logging
-q, --quiet           Minimal logging
--json                Output in JSON format (default is table)
```

### Commands

```bash
# Setup & Configuration
suth version                                   # Show version
suth setup                                     # Interactive setup wizard
suth config init                               # Create default config file
suth config show                               # Show current configuration
suth config set KEY VALUE                      # Set a config value
suth config path                               # Show config file path

# Workspaces
suth workspaces list                           # List available workspaces
suth workspaces use WORKSPACE_ID               # Set default workspace
suth workspaces current                        # Show current workspace

# Users
suth users me                                  # Get current user
suth users members                             # List workspace members

# Cards
suth cards get CARD_ID                         # Get card details
suth cards create --title "Task" --list "To Do" --board BOARD
suth cards update CARD_ID --title "New title"
suth cards delete CARD_ID
suth cards duplicate CARD_ID                   # Clone a card
suth cards assigned USER                       # Cards assigned to user
suth cards assign CARD_ID USER                 # Assign user to card
suth cards unassign CARD_ID USER               # Unassign user from card
suth cards link CARD_ID OTHER_ID --type blocks # Link cards (blocks, blocked_by, related, duplicates)
suth cards unlink CARD_ID OTHER_ID             # Remove card relationship

# Card Checklists
suth cards add-checklist CARD_ID --title "Tasks"
suth cards edit-checklist CARD_ID CHECKLIST_ID --title "New title"
suth cards rm-checklist CARD_ID CHECKLIST_ID
suth cards add-item CARD_ID CHECKLIST_ID --title "Item" [--checked]
suth cards edit-item CARD_ID CHECKLIST_ID ITEM_ID --title "New" [--checked]
suth cards rm-item CARD_ID CHECKLIST_ID ITEM_ID

# Card Tags
suth cards tags                                # List available tags
suth cards tag CARD_ID TAG1,TAG2               # Add tags to card
suth cards untag CARD_ID TAG                   # Remove tag from card

# Boards
suth boards list --space SPACE                 # List boards in a space (--space required)
suth boards get BOARD                          # Get board details
suth boards lists BOARD                        # List columns/lists on a board
suth boards create --title "Board" --space SPACE
suth boards update BOARD --title "New name"
suth boards duplicate BOARD                    # Clone a board
suth boards delete BOARD

# Board Lists (Columns)
suth boards list_create --board BOARD --title "Column"
suth boards list_update LIST_ID --title "New name"
suth boards list_delete LIST_ID

# Projects (Epics)
suth projects list                             # List all projects
suth projects get PROJECT_ID
suth projects create --title "Q1 Roadmap" --list LIST [--board BOARD]
suth projects update PROJECT_ID --title "New title"
suth projects delete PROJECT_ID
suth projects add_card PROJECT_ID CARD_ID      # Link card to project
suth projects remove_card PROJECT_ID CARD_ID   # Remove card from project

# Spaces
suth spaces list                               # List all spaces
suth spaces get SPACE
suth spaces create --title "Engineering"
suth spaces update SPACE --title "New name"
suth spaces delete SPACE
suth spaces add_member SPACE USER [--role ROLE]
suth spaces remove_member SPACE MEMBER_ID

# Pages
suth pages list [--space SPACE]                # List pages
suth pages get PAGE_ID
suth pages create --space SPACE [--title "Wiki"]
suth pages update PAGE_ID --title "New title"
suth pages duplicate PAGE_ID --space SPACE
suth pages archive PAGE_ID
suth pages delete PAGE_ID

# Comments
suth comments get COMMENT_ID
suth comments create --content "Looks good!" --card-id CARD
suth comments update COMMENT_ID --content "Updated"
suth comments delete COMMENT_ID
suth comments reply COMMENT_ID --content "Reply text"
suth comments replies COMMENT_ID               # Get replies to a comment
suth comments update_reply COMMENT_ID REPLY_ID --content "New"
suth comments delete_reply COMMENT_ID REPLY_ID

# Notes
suth notes list
suth notes get NOTE_ID
suth notes create --title "Meeting notes" [--transcript "..."] [--user-notes "..."]
suth notes delete NOTE_ID

# Sprints
suth sprints list --space SPACE
suth sprints get SPRINT_ID --space SPACE

# Search
suth search query "bug fix" [--types card,page] [--space SPACE] [--grouped]

# Tags
suth tags create --name "urgent" --color "#ff0000"
suth tags update TAG --name "critical"
suth tags delete TAG
```

### Option Aliases

Common options have short aliases:

| Long | Short | Description |
|------|-------|-------------|
| `--space` | `-s` | Space (ID or name) |
| `--board` | `-b` | Board (ID or name) |
| `--list` | `-l` | List (ID or name) |
| `--owner` | `-o` | Owner (user ID, name, or email) |
| `--force` | `-f` | Skip confirmation prompts |

### Tips

- Most commands accept **names or IDs** for spaces, boards, lists, users, and tags
- Use `-s SPACE` to help resolve ambiguous board/list names
- Use `--json` for scripted output: `suth cards assigned me --json`
- Use `me` as a user reference: `suth cards assigned me`
- Destructive commands prompt for confirmation; use `-f` or `--force` to skip
- Priority levels: 1=Urgent, 2=High, 3=Medium, 4=Low

## Library Usage

```ruby
require "superthread"

# Configure
Superthread.configure do |config|
  config.api_key = "stp_xxxxxxxxxxxx"
end

# Or use environment variables / config file (automatic)

# Create client
client = Superthread::Client.new

# Users
me = client.users.me                           # No workspace_id needed
members = client.users.members(workspace_id)

# Cards
card = client.cards.find(workspace_id, "crd_xxx")
card = client.cards.create(workspace_id,
  title: "New task",
  list_id: "lst_xxx",
  content: "Task description"
)
client.cards.update(workspace_id, "crd_xxx", title: "Updated title")
client.cards.delete(workspace_id, "crd_xxx")
cards = client.cards.assigned(workspace_id, user_id: "usr_xxx")

# Boards
boards = client.boards.list(workspace_id, space_id: "spc_xxx")
board = client.boards.create(workspace_id,
  title: "Sprint Board",
  space_id: "spc_xxx"
)

# Projects
projects = client.projects.list(workspace_id)
client.projects.add_card(workspace_id, "prj_xxx", "crd_xxx")

# Search
results = client.search.query(workspace_id,
  query: "bug",
  types: ["card", "page"],
  grouped: true
)
```

## Terminology

The gem uses Superthread's modern UI terminology:

| Term | Description |
|------|-------------|
| Workspace | Your team/organization account |
| Space | Organizational container (like a project folder) |
| Board | Kanban board with lists/columns |
| Project | Roadmap epic containing cards |
| Card | Task/issue on a board |
| Page | Wiki/documentation page |
| Note | Quick notes within a space |

## Development

```bash
git clone https://github.com/steveclarke/superthread.git
cd superthread
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec standardrb

# Run CLI locally
bundle exec bin/suth version
```

### Releasing

```bash
# Bump version (commits automatically)
rake bump:patch   # 0.0.x
rake bump:minor   # 0.x.0
rake bump:major   # x.0.0

# Release (creates tag, pushes, triggers GitHub Actions)
rake release
```

## License

MIT License - see [LICENSE](LICENSE) for details.
