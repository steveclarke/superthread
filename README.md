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

### Quick Setup

Run the interactive setup wizard:

```bash
suth setup
```

The wizard will:
1. Prompt for an account name (e.g., "personal" or "work")
2. Prompt for your API key (from Superthread Settings → API)
3. Validate and auto-detect your workspace
4. Save configuration

After setup, try:
```bash
suth spaces list
suth boards list -s SPACE
suth cards assigned me
```

### Multi-Account Support

You can configure multiple Superthread accounts (e.g., personal and work):

```bash
# Add another account
suth accounts add work

# List all accounts
suth accounts list

# Switch active account
suth accounts use work

# Use specific account for one command
suth --account personal cards assigned me
```

### Config Files

Configuration is split between a **config file** (credentials) and a **state file** (ephemeral context):

**Config file** (`~/.config/superthread/config.yaml`):
```yaml
# Account credentials
accounts:
  personal:
    api_key: stp_xxxxxxxxxxxx
  work:
    api_key: stp_yyyyyyyyyyyy

# Global preferences
format: table
```

**State file** (`~/.local/state/superthread/context.yaml`):
```yaml
current_account: personal
accounts:
  personal:
    workspace_id: t4k7Wa2e
    workspace_name: "My Team"
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
| `SUPERTHREAD_ACCOUNT` | Account name to use |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: `https://api.superthread.com/v1`) |

## CLI Usage

The CLI is available as `suth`.

### Global Options

```
-a, --account NAME    Use specific account for this command
-w, --workspace ID    Workspace ID (or use config/env var)
-y, --yes             Skip confirmation prompts (for scripts/agents)
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

# Accounts
suth accounts list                             # List all configured accounts
suth accounts show                             # Show current account details
suth accounts use NAME                         # Switch to account
suth accounts add NAME                         # Add new account (interactive)
suth accounts remove NAME                      # Remove account

# Workspaces
suth workspaces list                           # List available workspaces
suth workspaces use WORKSPACE                  # Set default workspace
suth workspaces current                        # Show current workspace

# Current User & Members
suth me                                        # Get current user info
suth members list                              # List workspace members

# Cards
suth cards list -b BOARD                       # List cards on a board
suth cards get CARD_ID                         # Get card details
suth cards create --title "Task" -l LIST -b BOARD
suth cards update CARD_ID --title "New title"
suth cards delete CARD_ID
suth cards duplicate CARD_ID                   # Clone a card
suth cards assigned USER                       # Cards assigned to user
suth cards assign CARD_ID USER                 # Assign user to card
suth cards unassign CARD_ID USER               # Unassign user from card
suth cards link --card CARD --related OTHER --type blocks  # Link cards
suth cards unlink --card CARD --related OTHER  # Remove card relationship

# Card Tags
suth cards tag CARD_ID TAG1,TAG2               # Add tags to card
suth cards untag CARD_ID TAG                   # Remove tag from card

# Boards
suth boards list -s SPACE                      # List boards in a space
suth boards get BOARD                          # Get board details
suth boards create --title "Board" -s SPACE
suth boards update BOARD --title "New name"
suth boards duplicate BOARD                    # Clone a board
suth boards delete BOARD

# Lists (Board Columns)
suth lists list -b BOARD                       # List columns on a board
suth lists create -b BOARD --title "Column"
suth lists update LIST_ID --title "New name"
suth lists delete LIST_ID

# Projects (Epics)
suth projects list                             # List all projects
suth projects get PROJECT_ID                   # Get project details
suth projects create --title "Q1 Roadmap" -l LIST [-b BOARD]
suth projects update PROJECT_ID --title "New title"
suth projects delete PROJECT_ID
suth projects add-card PROJECT_ID CARD_ID      # Link card to project
suth projects remove-card PROJECT_ID CARD_ID   # Remove card from project

# Spaces
suth spaces list                               # List all spaces
suth spaces get SPACE                          # Get space details
suth spaces create --title "Engineering"
suth spaces update SPACE --title "New name"
suth spaces delete SPACE
suth spaces add-member SPACE USER [--role ROLE]
suth spaces remove-member SPACE USER

# Pages
suth pages list [-s SPACE]                     # List pages
suth pages get PAGE_ID                    # Get page details
suth pages create -s SPACE [--title "Wiki"]
suth pages update PAGE_ID --title "New title"
suth pages duplicate PAGE_ID -s SPACE
suth pages archive PAGE_ID
suth pages delete PAGE_ID

# Comments
suth comments get COMMENT_ID                   # Get comment details
suth comments create --content "Looks good!" --card CARD
suth comments update COMMENT_ID --content "Updated"
suth comments delete COMMENT_ID

# Replies (Comment Threads)
suth replies list --comment COMMENT_ID         # List replies to a comment
suth replies get REPLY_ID                      # Get reply details
suth replies create --comment COMMENT_ID --content "Reply text"
suth replies update REPLY_ID --comment COMMENT_ID --content "Updated"
suth replies delete REPLY_ID --comment COMMENT_ID

# Checklists
suth checklists list -c CARD_ID                # List checklists on a card
suth checklists get CHECKLIST_ID -c CARD_ID    # Get checklist details
suth checklists create -c CARD_ID --title "Tasks"
suth checklists update CHECKLIST_ID -c CARD_ID --title "New title"
suth checklists delete CHECKLIST_ID -c CARD_ID
suth checklists add-item CHECKLIST_ID -c CARD_ID --title "Item"
suth checklists update-item ITEM_ID -c CARD_ID --checklist CL_ID --title "New"
suth checklists remove-item ITEM_ID -c CARD_ID --checklist CL_ID
suth checklists check ITEM_ID -c CARD_ID --checklist CL_ID
suth checklists uncheck ITEM_ID -c CARD_ID --checklist CL_ID

# Notes
suth notes list
suth notes get NOTE_ID                    # Get note details
suth notes create --title "Meeting notes" [--transcript "..."]
suth notes delete NOTE_ID

# Sprints
suth sprints list -s SPACE
suth sprints get SPRINT_ID -s SPACE

# Search
suth search query "bug fix" [--types card,page] [-s SPACE] [--grouped]

# Tags
suth tags list                                 # List available tags
suth tags list --all                           # Include unused tags
suth tags list -s SPACE                        # Filter by space
suth tags create --name "urgent" --color "#ff0000"
suth tags update TAG --name "critical"
suth tags delete TAG

# Shell Completion
suth completion bash                           # Generate bash completion script
suth completion zsh                            # Generate zsh completion script
suth completion fish                           # Generate fish completion script
```

### Shell Completion

**Setup (zsh):**
```bash
# Load for current session
source <(suth completion zsh)

# Load for every session (macOS with Homebrew)
suth completion zsh > $(brew --prefix)/share/zsh/site-functions/_suth
```

**Setup (bash):**
```bash
# Load for current session
source <(suth completion bash)

# Load for every session (macOS with Homebrew)
suth completion bash > $(brew --prefix)/etc/bash_completion.d/suth
```

**Setup (fish):**
```bash
suth completion fish > ~/.config/fish/completions/suth.fish
```

### Option Aliases

Common options have short aliases:

| Long | Short | Description |
|------|-------|-------------|
| `--space` | `-s` | Space (ID or name) |
| `--board` | `-b` | Board (ID or name) |
| `--list` | `-l` | List (ID or name) |
| `--card` | `-c` | Card ID |
| `--related` | `-r` | Related card ID |
| `--owner` | `-o` | Owner (user ID, name, or email) |
| `--yes` | `-y` | Skip confirmation prompts |

### Tips

- Most commands accept **names or IDs** for spaces, boards, lists, users, and tags
- Use `-s SPACE` to help resolve ambiguous board/list names
- Use `--json` for scripted output: `suth cards assigned me --json`
- Use `me` as a user reference: `suth cards assigned me`
- Use `-y` to skip confirmation prompts (for scripts/agents)
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

# Run code linter
bundle exec standardrb

# Run documentation linter
rake yard:lint

# Run CLI locally
bundle exec bin/suth version
```

### Documentation

This project uses [yard-lint](https://github.com/mensfeld/yard-lint) to enforce YARD documentation standards. See [docs/yard-linting.md](docs/yard-linting.md) for the full guide.

```bash
# Check all files
rake yard:lint

# Or run directly with options
bundle exec yard-lint lib/ --stats    # With coverage stats
bundle exec yard-lint lib/ --diff main # Only changed files
```

### Git Hooks

This project uses [Lefthook](https://github.com/evilmartians/lefthook) for pre-commit hooks.

```bash
# Install lefthook (macOS)
brew install lefthook

# Set up hooks
lefthook install
```

The pre-commit hook runs StandardRB and yard-lint on staged files.

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
