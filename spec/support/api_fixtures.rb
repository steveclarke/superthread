# frozen_string_literal: true

# API response fixtures for WebMock stubs.
# Extracted from VCR cassettes to maintain identical test behavior.
#
module ApiFixtures
  # Generic success response
  SUCCESS = {success: true}.freeze

  module Cards
    GET = {
      card: {
        id: "card-123",
        title: "Implement feature X",
        status: "started",
        priority: 2,
        board_id: "10",
        board_title: "Sprint Board",
        list_id: "101",
        list_title: "In Progress",
        time_created: 1705312200000,
        time_updated: 1705398600000,
        is_watching: true,
        members: [{user_id: "u123abc", role: "assignee"}],
        tags: [{id: "tag-1", name: "backend", color: "blue"}],
        checklists: []
      }
    }.freeze

    CREATE = {
      card: {
        id: "card-new-1",
        title: "New card from CLI",
        status: "not_started",
        priority: 3,
        board_id: "10",
        board_title: "Sprint Board",
        list_id: "101",
        list_title: "In Progress",
        time_created: 1705312200000,
        time_updated: 1705312200000,
        is_watching: false,
        members: [],
        tags: [],
        checklists: []
      }
    }.freeze

    UPDATE = {
      card: {
        id: "card-123",
        title: "Updated card title",
        status: "started",
        priority: 1,
        board_id: "10",
        board_title: "Sprint Board",
        list_id: "101",
        list_title: "In Progress",
        time_created: 1705312200000,
        time_updated: 1705399000000,
        is_watching: true,
        members: [{user_id: "u123abc", role: "assignee"}],
        tags: [{id: "tag-1", name: "backend", color: "blue"}],
        checklists: []
      }
    }.freeze

    DUPLICATE = {
      card: {
        id: "card-dup-1",
        title: "Copy of Implement feature X",
        status: "started",
        priority: 2,
        board_id: "10",
        board_title: "Sprint Board",
        list_id: "101",
        list_title: "In Progress",
        time_created: 1705312200000,
        time_updated: 1705312200000,
        is_watching: false,
        members: [],
        tags: [{id: "tag-1", name: "backend", color: "blue"}],
        checklists: []
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      card: {
        id: "card-to-delete",
        title: "Card to Delete",
        status: "open",
        priority: 3,
        board_id: "10",
        list_id: "100",
        list_title: "To Do",
        time_created: 1705312200000,
        checklists: []
      }
    }.freeze

    # Card with checklist for remove_checklist/remove_item tests
    WITH_CHECKLIST = {
      card: {
        id: "card-123",
        title: "Card with Checklist",
        status: "started",
        checklists: [
          {
            id: "checklist-to-delete",
            title: "Checklist to Delete",
            card_id: "card-123",
            items: [
              {id: "item-to-delete", title: "Item to Delete", checked: false, position: 0}
            ]
          }
        ]
      }
    }.freeze

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

    ASSIGNED = {
      cards: [
        {id: "card-123", title: "Implement feature X", status: "started", priority: 2, list_title: "In Progress"},
        {id: "card-456", title: "Fix bug Y", status: "open", priority: 1, list_title: "To Do"}
      ]
    }.freeze

    CHECKLIST_CREATE = {
      id: "checklist-1",
      title: "Implementation Tasks",
      card_id: "card-123",
      time_created: 1705312200000,
      items: []
    }.freeze

    CHECKLIST_ITEM_CREATE = {
      id: "item-1",
      title: "Write unit tests",
      checked: false,
      checklist_id: "checklist-1",
      position: 0
    }.freeze

    CHECKLIST_ITEM_UPDATE = {
      id: "item-1",
      title: "Updated item",
      checked: true,
      checklist_id: "checklist-1",
      position: 0
    }.freeze

    CHECKLIST_UPDATE = {
      id: "checklist-1",
      title: "Updated checklist",
      card_id: "card-123",
      time_created: 1705312200000,
      items: []
    }.freeze
  end

  module Tags
    LIST = {
      tags: [
        {id: "tag-1", name: "backend", color: "blue", total_cards: 15},
        {id: "tag-2", name: "frontend", color: "green", total_cards: 22},
        {id: "tag-3", name: "bug", color: "red", total_cards: 8}
      ]
    }.freeze

    CREATE = {
      tag: {
        id: "tag-new-1",
        name: "urgent",
        color: "#ff0000",
        time_created: 1705398600000
      }
    }.freeze

    UPDATE = {
      tag: {
        id: "tag-1",
        name: "critical",
        color: "#ff5500",
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    # Tag list for delete confirmation (fetched via client.cards.tags)
    LIST_WITH_DELETE_TAG = {
      tags: [
        {id: "tag-1", name: "backend", color: "blue", total_cards: 15},
        {id: "tag-to-delete", name: "Tag to Delete", color: "red", total_cards: 0}
      ]
    }.freeze
  end

  module Boards
    LIST = {
      boards: [
        {
          id: "10",
          team_id: "team-1",
          title: "Sprint Board",
          user_id: "user-1",
          time_created: 1705312200,
          time_updated: 1705312200,
          lists: [
            {id: "100", title: "To Do", color: "gray", position: 0},
            {id: "101", title: "In Progress", color: "blue", position: 1}
          ]
        },
        {id: "11", team_id: "team-1", title: "Backlog", user_id: "user-1", time_created: 1705398600, time_updated: 1705398600, lists: []}
      ]
    }.freeze

    GET = {
      board: {
        id: "10",
        team_id: "team-1",
        title: "Sprint Board",
        user_id: "user-1",
        time_created: 1705312200,
        time_updated: 1705398600,
        lists: [
          {id: "100", title: "To Do", color: "gray", position: 0},
          {id: "101", title: "In Progress", color: "blue", position: 1},
          {id: "102", title: "Done", color: "green", position: 2}
        ]
      }
    }.freeze

    CREATE = {
      board: {
        id: "board-new-1",
        team_id: "team-1",
        title: "New Board",
        user_id: "user-1",
        time_created: 1705312200,
        time_updated: 1705312200,
        lists: []
      }
    }.freeze

    UPDATE = {
      board: {
        id: "10",
        team_id: "team-1",
        title: "Updated Sprint Board",
        user_id: "user-1",
        time_created: 1705312200,
        time_updated: 1705399000,
        lists: [
          {id: "100", title: "To Do", color: "gray", position: 0},
          {id: "101", title: "In Progress", color: "blue", position: 1},
          {id: "102", title: "Done", color: "green", position: 2}
        ]
      }
    }.freeze

    DUPLICATE = {
      board: {
        id: "board-dup-1",
        team_id: "team-1",
        title: "Copy of Sprint Board",
        user_id: "user-1",
        time_created: 1705312200,
        time_updated: 1705312200,
        lists: [
          {id: "200", title: "To Do", color: "gray", position: 0},
          {id: "201", title: "In Progress", color: "blue", position: 1},
          {id: "202", title: "Done", color: "green", position: 2}
        ]
      }
    }.freeze

    LIST_CREATE = {
      list: {
        id: "103",
        title: "Review",
        color: "purple",
        board_id: "10",
        position: 3
      }
    }.freeze

    LIST_UPDATE = {
      list: {
        id: "100",
        title: "Backlog",
        color: "gray",
        board_id: "10",
        position: 0
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      board: {
        id: "board-to-delete",
        team_id: "team-1",
        title: "Board to Delete",
        user_id: "user-1",
        time_created: 1705312200,
        time_updated: 1705312200,
        lists: []
      }
    }.freeze
  end

  module Users
    ME = {
      user: {
        user_id: "u123abc",
        display_name: "Test User",
        email: "test@example.com",
        role: "admin",
        time_created: 1705312200000,
        time_updated: 1705398600000
      }
    }.freeze

    MEMBERS = {
      members: [
        {user_id: "u123abc", display_name: "Test User", email: "test@example.com", role: "owner"},
        {user_id: "u456def", display_name: "Another User", email: "another@example.com", role: "member"}
      ]
    }.freeze
  end

  module Spaces
    LIST = {
      projects: [
        {id: "1", title: "Engineering", description: "Engineering team space", time_created: 1705312200000},
        {id: "2", title: "Design", description: "Design team space", time_created: 1705398600000}
      ]
    }.freeze

    GET = {
      project: {
        id: "1",
        title: "Engineering",
        description: "Engineering team space",
        icon: "code",
        time_created: 1705312200000,
        time_updated: 1705398600000,
        members: [{user_id: "u123abc", role: "admin"}]
      }
    }.freeze

    CREATE = {
      project: {
        id: "space-new-1",
        title: "Marketing",
        description: "Marketing team space",
        time_created: 1705398600000
      }
    }.freeze

    UPDATE = {
      project: {
        id: "1",
        title: "Engineering Team",
        description: "Engineering team space",
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      project: {
        id: "space-to-delete",
        title: "Space to Delete",
        time_created: 1705312200000
      }
    }.freeze

    ADD_MEMBER = {
      member: {
        id: "member-new-1",
        user_id: "user-123",
        space_id: "1",
        role: "member",
        time_created: 1705312200000
      }
    }.freeze

    ADD_MEMBER_ROLE = {
      member: {
        id: "member-new-2",
        user_id: "user-123",
        space_id: "1",
        role: "admin",
        time_created: 1705312200000
      }
    }.freeze
  end

  module Projects
    # API returns epics nested inside lists (status columns)
    LIST = {
      list_order: ["1", "2"],
      lists: [
        {
          id: "1",
          title: "In Progress",
          behavior: "started",
          epics: [
            {id: "proj-1", title: "Q1 Roadmap", type: "epic", time_created: 1705312200000}
          ]
        },
        {
          id: "2",
          title: "Planned",
          behavior: "committed",
          epics: [
            {id: "proj-2", title: "Mobile App", type: "epic", time_created: 1705398600000}
          ]
        }
      ],
      time_updated: 0
    }.freeze

    GET = {
      epic: {
        id: "proj-1",
        title: "Q1 Roadmap",
        status: "in_progress",
        start_date: 1705312200000,
        due_date: 1713174600000,
        time_created: 1705312200000,
        time_updated: 1705398600000
      }
    }.freeze

    CREATE = {
      epic: {
        id: "proj-new-1",
        title: "New Project",
        status: "planned",
        list_id: "100",
        time_created: 1705398600000
      }
    }.freeze

    UPDATE = {
      epic: {
        id: "proj-1",
        title: "Updated Roadmap",
        status: "in_progress",
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      epic: {
        id: "proj-to-delete",
        title: "Project to Delete",
        status: "planned",
        time_created: 1705312200000
      }
    }.freeze
  end

  module Comments
    LIST = {
      comments: [
        {id: "comment-1", content: "<p>First comment</p>", user_id: "user-1", card_id: "card-123", time_created: 1705312200000},
        {id: "comment-2", content: "<p>Second comment</p>", user_id: "user-2", card_id: "card-123", time_created: 1705398600000}
      ]
    }.freeze

    GET = {
      comment: {
        id: "comment-1",
        content: "<p>This is a test comment</p>",
        user_id: "user-1",
        card_id: "card-123",
        time_created: 1705312200000,
        time_updated: 1705398600000
      }
    }.freeze

    CREATE = {
      comment: {
        id: "comment-new-1",
        content: "<p>New comment content</p>",
        user_id: "user-1",
        card_id: "card-123",
        time_created: 1705398600000
      }
    }.freeze

    UPDATE = {
      comment: {
        id: "comment-1",
        content: "<p>Updated content</p>",
        user_id: "user-1",
        card_id: "card-123",
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    REPLIES = {
      child_comments: [
        {id: "reply-1", content: "<p>Reply 1</p>", user_id: "user-1", time_created: 1705312200000},
        {id: "reply-2", content: "<p>Reply 2</p>", user_id: "user-2", time_created: 1705398600000}
      ]
    }.freeze

    REPLY_CREATE = {
      child_comment: {
        id: "reply-1",
        content: "<p>This is a reply</p>",
        user_id: "user-1",
        time_created: 1705398600000
      }
    }.freeze

    REPLY_UPDATE = {
      child_comment: {
        id: "reply-1",
        content: "<p>Updated reply</p>",
        user_id: "user-1",
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      comment: {
        id: "comment-to-delete",
        content: "<p>Comment to delete</p>",
        user_id: "user-1",
        card_id: "card-123",
        time_created: 1705312200000
      }
    }.freeze

    # Used for find_reply lookup in delete confirmation
    REPLIES_WITH_DELETE_TARGET = {
      child_comments: [
        {id: "reply-to-delete", content: "<p>Reply to delete</p>", user_id: "user-1", time_created: 1705312200000}
      ]
    }.freeze
  end

  module Notes
    LIST = {
      notes: [
        {id: "note-1", title: "Meeting Notes", time_created: 1705312200000},
        {id: "note-2", title: "Standup Summary", time_created: 1705398600000}
      ]
    }.freeze

    GET = {
      note: {
        id: "note-1",
        title: "Meeting Notes",
        content: "Discussion points from the team meeting",
        transcript: "Full transcript here",
        time_created: 1705312200000,
        time_updated: 1705398600000
      }
    }.freeze

    CREATE = {
      note: {
        id: "note-new-1",
        title: "New Note",
        transcript: "Meeting transcript content",
        time_created: 1705398600000
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      note: {
        id: "note-to-delete",
        title: "Note to Delete",
        time_created: 1705312200000
      }
    }.freeze
  end

  module Pages
    LIST = {
      pages: [
        {id: "page-1", title: "Getting Started", space_id: "1", time_created: 1705312200000},
        {id: "page-2", title: "API Documentation", space_id: "1", time_created: 1705398600000}
      ]
    }.freeze

    GET = {
      page: {
        id: "page-1",
        title: "Getting Started",
        space_id: "1",
        content: "Welcome to the getting started guide",
        time_created: 1705312200000,
        time_updated: 1705398600000
      }
    }.freeze

    CREATE = {
      page: {
        id: "page-new-1",
        title: "New Page",
        space_id: "1",
        content: "Page content here",
        time_created: 1705398600000
      }
    }.freeze

    UPDATE = {
      page: {
        id: "page-1",
        title: "Updated Page Title",
        space_id: "1",
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    DUPLICATE = {
      page: {
        id: "page-dup-1",
        title: "Copy of Getting Started",
        space_id: "1",
        time_created: 1705398600000
      }
    }.freeze

    ARCHIVE = {
      page: {
        id: "page-1",
        title: "Getting Started",
        space_id: "1",
        archived: true,
        time_created: 1705312200000,
        time_updated: 1705485000000
      }
    }.freeze

    # Used for delete confirmation
    DELETE = {
      page: {
        id: "page-to-delete",
        title: "Page to Delete",
        space_id: "1",
        time_created: 1705312200000
      }
    }.freeze
  end

  module Sprints
    LIST = {
      sprints: [
        {id: "sprint-1", team_id: "team-1", title: "Sprint 1", start_date: 1705312200, time_created: 1705312200, time_updated: 1705312200},
        {id: "sprint-2", team_id: "team-1", title: "Sprint 2", start_date: 1706521800, time_created: 1705398600, time_updated: 1705398600}
      ]
    }.freeze

    GET = {
      sprint: {
        id: "sprint-1",
        team_id: "team-1",
        title: "Sprint 1",
        start_date: 1705312200,
        time_created: 1705312200,
        time_updated: 1705398600,
        lists: [
          {id: "sprint-list-1", title: "To do"},
          {id: "sprint-list-2", title: "Doing"},
          {id: "sprint-list-3", title: "Done"}
        ]
      }
    }.freeze
  end

  module Search
    # API returns wrapped objects when grouped=false (our default)
    RESULTS = {
      count: 2,
      cursor: "",
      results: [
        {card: {id: "card-auth", title: "Auth Module", board_id: "1", list_id: "1", project_id: "1"}},
        {page: {id: "page-login", title: "Login Flow", space_id: "1"}}
      ]
    }.freeze

    RESULTS_TYPED = {
      count: 1,
      cursor: "",
      results: [
        {card: {id: "card-auth", title: "Auth Module", board_id: "1", list_id: "1", project_id: "1"}}
      ]
    }.freeze

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
  end

  module Workspaces
    LIST = {
      user: {
        id: "user-1",
        name: "Test User",
        email: "test@example.com",
        teams: [
          {id: "ws-123", team_name: "My Team", role: "admin"},
          {id: "ws-456", team_name: "Other Team", role: "member"}
        ]
      }
    }.freeze
  end

  module Errors
    NOT_FOUND = {error: "Card not found"}.freeze
  end
end
