# Superthread

Ruby gem and CLI for [Superthread](https://superthread.com) project management.

## Installation

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
st config init
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPERTHREAD_API_KEY` | API key (overrides config file) |
| `SUPERTHREAD_WORKSPACE_ID` | Default workspace ID |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: `https://api.superthread.com/v1`) |

## CLI Usage

The CLI is available as `st` (or `superthread`).

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
st users me                              # Get current user
st users members                         # List workspace members

# Cards
st cards list --board-id brd_xxx         # List cards on a board
st cards get CARD_ID                     # Get card details
st cards create --title "Task" --list-id lst_xxx
st cards update CARD_ID --title "New title"
st cards delete CARD_ID
st cards assigned                        # Cards assigned to you
st cards add-member CARD_ID --user-id usr_xxx
st cards remove-member CARD_ID --user-id usr_xxx

# Boards
st boards list                           # List all boards
st boards get BOARD_ID                   # Get board details
st boards create --name "Sprint Board" --space-id spc_xxx
st boards update BOARD_ID --name "New name"
st boards delete BOARD_ID
st boards lists BOARD_ID                 # Get board lists/columns

# Projects (Epics)
st projects list                         # List all projects
st projects get PROJECT_ID
st projects create --name "Q1 Roadmap" --space-id spc_xxx
st projects add-card PROJECT_ID --card-id crd_xxx
st projects remove-card PROJECT_ID --card-id crd_xxx

# Spaces
st spaces list                           # List all spaces
st spaces get SPACE_ID
st spaces create --name "Engineering"
st spaces add-member SPACE_ID --user-id usr_xxx
st spaces remove-member SPACE_ID --user-id usr_xxx

# Pages
st pages list --space-id spc_xxx         # List pages in a space
st pages get PAGE_ID
st pages create --title "Wiki" --space-id spc_xxx
st pages archive PAGE_ID
st pages delete PAGE_ID

# Comments
st comments get COMMENT_ID
st comments create --card-id crd_xxx --content "Looks good!"
st comments update COMMENT_ID --content "Updated comment"
st comments delete COMMENT_ID
st comments replies COMMENT_ID           # Get replies to a comment

# Notes
st notes list --space-id spc_xxx
st notes get NOTE_ID
st notes create --title "Meeting notes" --space-id spc_xxx
st notes delete NOTE_ID

# Sprints
st sprints list --space-id spc_xxx
st sprints get SPRINT_ID --space-id spc_xxx

# Search
st search query "bug fix" --types card,page

# Tags
st tags create --name "urgent" --color "#ff0000"
st tags update TAG_ID --name "critical"
st tags delete TAG_ID
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
bundle exec bin/st version
```

## License

MIT License - see [LICENSE](LICENSE) for details.
