# Superthread

Ruby gem and CLI for [Superthread](https://superthread.com) project management.

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

# Default workspace ID (optional)
workspace: ws_abc123

# Output format: json or table
format: json

# Workspace aliases for quick switching
workspaces:
  personal: ws_abc123
  work: ws_def456
```

Initialize with defaults:

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
--format FORMAT       Output format: json (default) or table
```

### Commands

```bash
# Users
suth users me                              # Get current user
suth users members                         # List workspace members

# Cards
suth cards list --board-id brd_xxx         # List cards on a board
suth cards get CARD_ID                     # Get card details
suth cards create --title "Task" --list-id lst_xxx
suth cards update CARD_ID --title "New title"
suth cards delete CARD_ID
suth cards assigned                        # Cards assigned to you
suth cards add-member CARD_ID --user-id usr_xxx
suth cards remove-member CARD_ID --user-id usr_xxx

# Boards
suth boards list                           # List all boards
suth boards get BOARD_ID                   # Get board details
suth boards create --name "Sprint Board" --space-id spc_xxx
suth boards update BOARD_ID --name "New name"
suth boards delete BOARD_ID
suth boards lists BOARD_ID                 # Get board lists/columns

# Projects (Epics)
suth projects list                         # List all projects
suth projects get PROJECT_ID
suth projects create --name "Q1 Roadmap" --space-id spc_xxx
suth projects add-card PROJECT_ID --card-id crd_xxx
suth projects remove-card PROJECT_ID --card-id crd_xxx

# Spaces
suth spaces list                           # List all spaces
suth spaces get SPACE_ID
suth spaces create --name "Engineering"
suth spaces add-member SPACE_ID --user-id usr_xxx
suth spaces remove-member SPACE_ID --user-id usr_xxx

# Pages
suth pages list --space-id spc_xxx         # List pages in a space
suth pages get PAGE_ID
suth pages create --title "Wiki" --space-id spc_xxx
suth pages archive PAGE_ID
suth pages delete PAGE_ID

# Comments
suth comments get COMMENT_ID
suth comments create --card-id crd_xxx --content "Looks good!"
suth comments update COMMENT_ID --content "Updated comment"
suth comments delete COMMENT_ID
suth comments replies COMMENT_ID           # Get replies to a comment

# Notes
suth notes list --space-id spc_xxx
suth notes get NOTE_ID
suth notes create --title "Meeting notes" --space-id spc_xxx
suth notes delete NOTE_ID

# Sprints
suth sprints list --space-id spc_xxx
suth sprints get SPRINT_ID --space-id spc_xxx

# Search
suth search query "bug fix" --types card,page

# Tags
suth tags create --name "urgent" --color "#ff0000"
suth tags update TAG_ID --name "critical"
suth tags delete TAG_ID
```

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
me = client.users.me(workspace_id)
members = client.users.members(workspace_id)

# Cards
cards = client.cards.list(workspace_id, board_id: "brd_xxx")
card = client.cards.get(workspace_id, "crd_xxx")
card = client.cards.create(workspace_id,
  title: "New task",
  list_id: "lst_xxx",
  content: "Task description"
)
client.cards.update(workspace_id, "crd_xxx", title: "Updated title")
client.cards.delete(workspace_id, "crd_xxx")

# Boards
boards = client.boards.list(workspace_id)
board = client.boards.create(workspace_id,
  name: "Sprint Board",
  space_id: "spc_xxx"
)

# Projects
projects = client.projects.list(workspace_id)
client.projects.add_card(workspace_id, "prj_xxx", card_id: "crd_xxx")

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

# Run CLI locally
bundle exec bin/suth version
```

## License

MIT License - see [LICENSE](LICENSE) for details.
