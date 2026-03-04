# Superthread

A Ruby gem and CLI to manage your [Superthread](https://superthread.com) projects from the terminal.

Create cards, move tasks, search your workspace, and run scripts — right from the terminal. Works great with AI agents too.

> [!WARNING]
> **Pre-Release Software**
>
> This project is not made by Superthread. It is built and kept up by the community.
>
> We made this for our own work and use it every day. But it may still have bugs or missing features. Things may change without notice.
>
> **Test in a safe place first** before you depend on it. Bug reports and pull requests are welcome.

## Table of Contents

- [Install](#install)
- [Setup](#setup)
- [CLI Usage](#cli-usage)
- [Library Usage](#library-usage)
- [Key Terms](#key-terms)
- [Agents and Scripts](#agents-and-scripts)
- [Development](#development)
- [License](#license)

## Install

### Homebrew (best option)

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

## Setup

### Quick Setup

Run the setup wizard:

```bash
suth setup
```

It will:
1. Ask for an account name (like "personal" or "work")
2. Ask for your API key (find it in Superthread Settings → API)
3. Find your workspace
4. Save your settings

Then try these commands:
```bash
suth spaces list
suth boards list -s SPACE
suth cards assigned me
```

### More Than One Account

You can set up more than one account:

```bash
# Add another account
suth accounts add work

# See all accounts
suth accounts list

# Switch accounts
suth accounts use work

# Use a specific account for one command
suth --account personal cards assigned me
```

### Config Files

Settings live in two files:

**Config file** (`~/.config/superthread/config.yaml`) — your keys:
```yaml
accounts:
  personal:
    api_key: stp_xxxxxxxxxxxx
  work:
    api_key: stp_yyyyyyyyyyyy

format: table
```

**State file** (`~/.local/state/superthread/context.yaml`) — your active session:
```yaml
current_account: personal
accounts:
  personal:
    workspace_id: t4k7Wa2e
    workspace_name: "My Team"
```

You can also create a blank config file by hand:

```bash
suth config init
```

### Env Vars

| Variable | What it does |
|----------|-------------|
| `SUPERTHREAD_API_KEY` | API key (wins over config file) |
| `SUPERTHREAD_WORKSPACE_ID` | Default workspace ID |
| `SUPERTHREAD_ACCOUNT` | Account name to use |
| `SUPERTHREAD_API_BASE_URL` | API endpoint (default: `https://api.superthread.com/v1`) |

## CLI Usage

The CLI command is `suth`.

### Global Options

```
-a, --account NAME    Use a specific account
-w, --workspace ID    Set the workspace (ID or name)
-y, --yes             Skip "are you sure?" prompts
-v, --verbose         Show more detail
-q, --quiet           Show less detail
--json                Output as JSON (default is a table)
```

### Commands

```bash
# Setup & Configuration
suth version                                   # Show version
suth setup                                     # Run the setup wizard
suth config init                               # Create a config file
suth config show                               # Show your settings
suth config set KEY VALUE                      # Change a setting
suth config path                               # Show config file path

# Accounts
suth accounts list                             # List all accounts
suth accounts show                             # Show current account
suth accounts use NAME                         # Switch to an account
suth accounts add NAME                         # Add a new account
suth accounts remove NAME                      # Remove an account

# Workspaces
suth workspaces list                           # List workspaces
suth workspaces use WORKSPACE                  # Set your workspace
suth workspaces current                        # Show current workspace

# Current User & Members
suth me                                        # Your user info
suth members list                              # List workspace members

# Cards
suth cards list -b BOARD                       # List cards on a board
suth cards list --sprint SPRINT -s SPACE       # List cards in a sprint
suth cards get CARD_ID                         # Get card details
suth cards create --title "Task" -l LIST -b BOARD
suth cards create --title "Task" -l LIST --sprint SPRINT -s SPACE
suth cards update CARD_ID --title "New title"
suth cards update CARD_ID --sprint SPRINT -s SPACE  # Move to sprint
suth cards update CARD_ID -l "Done"            # Move card to a list
suth cards delete CARD_ID
suth cards duplicate CARD_ID                   # Copy a card
suth cards assigned USER                       # Cards for a user
suth cards assign CARD_ID USER                 # Assign someone to a card
suth cards unassign CARD_ID USER               # Remove someone from a card
suth cards link --card CARD --related OTHER --type blocks
suth cards unlink --card CARD --related OTHER

# Card Tags
suth cards tag CARD_ID TAG1,TAG2               # Add tags
suth cards untag CARD_ID TAG                   # Remove a tag

# Boards
suth boards list -s SPACE                      # List boards in a space
suth boards get BOARD                          # Get board details
suth boards create --title "Board" -s SPACE
suth boards update BOARD --title "New name"
suth boards duplicate BOARD                    # Copy a board
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
suth projects add-card PROJECT_ID CARD_ID      # Add a card to a project
suth projects remove-card PROJECT_ID CARD_ID   # Remove a card

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
suth pages get PAGE_ID                         # Get page details
suth pages create -s SPACE [--title "Wiki"]
suth pages update PAGE_ID --title "New title"
suth pages duplicate PAGE_ID -s SPACE
suth pages archive PAGE_ID
suth pages delete PAGE_ID

# Comments
suth comments get COMMENT_ID                   # Get a comment
suth comments create --content "Looks good!" --card CARD
suth comments update COMMENT_ID --content "Updated"
suth comments delete COMMENT_ID

# Replies
suth replies list --comment COMMENT_ID         # List replies
suth replies get REPLY_ID                      # Get a reply
suth replies create --comment COMMENT_ID --content "Reply text"
suth replies update REPLY_ID --comment COMMENT_ID --content "Updated"
suth replies delete REPLY_ID --comment COMMENT_ID

# Checklists
suth checklists list -c CARD_ID               # List checklists on a card
suth checklists get CHECKLIST_ID -c CARD_ID
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
suth notes get NOTE_ID
suth notes create --title "Meeting notes" [--transcript "..."]
suth notes delete NOTE_ID

# Sprints
suth sprints list -s SPACE
suth sprints get SPRINT_ID -s SPACE

# Search
suth search query "bug fix" [--types card,page] [-s SPACE] [--grouped]

# Tags
suth tags list                                 # List all tags
suth tags list --all                           # Include unused tags
suth tags list -s SPACE                        # Filter by space
suth tags create --name "urgent" --color "#ff0000"
suth tags update TAG --name "critical"
suth tags delete TAG

# Shell Completion
suth completion bash
suth completion zsh
suth completion fish
```

### Shell Completion

Set up tab help for your shell:

**zsh:**
```bash
# Load now
source <(suth completion zsh)

# Load every time (macOS with Homebrew)
suth completion zsh > $(brew --prefix)/share/zsh/site-functions/_suth
```

**bash:**
```bash
# Load now
source <(suth completion bash)

# Load every time (macOS with Homebrew)
suth completion bash > $(brew --prefix)/etc/bash_completion.d/suth
```

**fish:**
```bash
suth completion fish > ~/.config/fish/completions/suth.fish
```

### Option Aliases

Common options have short forms:

| Long | Short | What it means |
|------|-------|-------------|
| `--space` | `-s` | Space (ID or name) |
| `--board` | `-b` | Board (ID or name) |
| `--list` | `-l` | List (ID or name) |
| `--card` | `-c` | Card ID |
| `--related` | `-r` | Related card ID |
| `--owner` | `-o` | Owner (user ID, name, or email) |
| `--yes` | `-y` | Skip prompts |

> [!TIP]
> - Most commands accept **names or IDs** for spaces, boards, lists, sprints, users, and tags
> - Use `-s SPACE` to help when board or list names are unclear
> - Use `--json` for scripted output: `suth cards assigned me --json`
> - Use `me` as a shortcut: `suth cards assigned me`
> - Priority levels: 1=Urgent, 2=High, 3=Medium, 4=Low

## Library Usage

You can also use Superthread as a Ruby gem in your code:

```ruby
require "superthread"

# Set up
Superthread.configure do |config|
  config.api_key = "stp_xxxxxxxxxxxx"
end

# Or use env vars — they work on their own

# Create a client
client = Superthread::Client.new

# Users
me = client.users.me
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

## Key Terms

Superthread uses these terms:

| Term | What it is |
|------|------------|
| Workspace | Your team or company account |
| Space | A folder that holds boards, pages, and sprints |
| Board | A kanban board with columns |
| Project | A big goal (epic) that holds many cards |
| Card | A task or issue on a board |
| Page | A wiki or document |
| Note | A quick note in a space |

## Agents and Scripts

This CLI works well with AI agents, scripts, and CI jobs. Every command can give you JSON and run with no prompts.

### Built for automation

- **`--json` on every command** — Get JSON instead of tables. Easy for agents to read.
- **`-y` to skip prompts** — Delete and remove ask "are you sure?" by default. Pass `-y` to skip that. Scripts can run with no waiting.
- **Env vars for setup** — Set `SUPERTHREAD_API_KEY` and `SUPERTHREAD_WORKSPACE_ID` and you are ready. No config files. No wizard.
- **Clear errors** — Bad commands return non-zero exit codes. With `--json`, errors come back as JSON too.

### Example: create a card from a script

```bash
export SUPERTHREAD_API_KEY="stp_xxxxxxxxxxxx"
export SUPERTHREAD_WORKSPACE_ID="t4k7Wa2e"

# Create a card and get the new ID
suth cards create \
  --title "Deploy v2.1 to staging" \
  --list "To Do" \
  --board "Sprint Board" \
  -s "Engineering" \
  --json | jq -r '.id'
```

Agents can chain commands — create a card, assign it, add a checklist, post a comment — all with no human input.

### Claude Code skill

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill is included. It teaches agents every CLI command. With the skill, agents don't need to run `--help` first.

```bash
npx skills add steveclarke/superthread
```

Once installed, type `/superthread` in any Claude Code session. It also starts on its own when you work with Superthread tasks.

## Development

```bash
git clone https://github.com/steveclarke/superthread.git
cd superthread
bundle install

# Run tests
bundle exec rspec

# Check code style
bundle exec standardrb

# Check docs
rake yard:lint

# Run the CLI
bundle exec bin/suth version
```

See [CONTRIBUTING.md](CONTRIBUTING.md) to learn more.

### Key Files and Folders

| Path | What's inside |
|------|--------------|
| `lib/superthread/` | The Ruby gem (models, resources, client) |
| `lib/superthread/cli/` | CLI commands (one file per group) |
| `exe/suth` | The CLI entry point |
| `spec/` | Tests (RSpec) |
| `skills/superthread/` | Claude Code skill for the CLI |
| `docs/` | Guides for devs |

### Git Hooks

This project uses [Lefthook](https://github.com/evilmartians/lefthook) to check code before each commit:

```bash
brew install lefthook
lefthook install
```

The hook checks code style (StandardRB) and docs (yard-lint) on staged files before each commit.

### Releasing

```bash
# Bump version
rake bump:patch   # 0.0.x
rake bump:minor   # 0.x.0
rake bump:major   # x.0.0

# Release (creates a tag, pushes it, GitHub Actions does the rest)
rake release
```

## License

MIT License — see [LICENSE](LICENSE) for details.
