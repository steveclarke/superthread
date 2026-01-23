# frozen_string_literal: true

RSpec.describe Superthread::Objects::Card do
  let(:card_data) do
    {
      id: "card-123",
      type: "card",
      team_id: "team-1",
      project_id: "project-1",
      title: "Implement feature X",
      content: "Description here",
      schema: "1.0",
      status: "started",
      priority: 2,
      estimate: 5,
      board_id: "board-1",
      board_title: "Sprint Board",
      list_id: "list-1",
      list_title: "In Progress",
      list_color: "yellow",
      sprint_id: "sprint-1",
      owner_id: "user-1",
      user_id: "user-1",
      user_id_updated: "user-2",
      start_date: 1705312200000,
      due_date: 1705916400000,
      completed_date: nil,
      time_created: 1705312200000,
      time_updated: 1705398600000,
      total_comments: 3,
      total_files: 2,
      is_watching: true,
      is_bookmarked: false,
      archived_list: false,
      archived_board: false,
      members: [
        {user_id: "user-1", role: "admin", assigned_date: 1705312200000}
      ],
      checklists: [
        {id: "checklist-1", title: "Tasks", items: []}
      ],
      tags: [
        {id: "tag-1", name: "bug", color: "red"}
      ],
      child_cards: [
        {id: "card-child-1", title: "Subtask 1"}
      ],
      linked_cards: [
        {id: "card-linked-1", title: "Related Card", linked_card_type: "blocks"}
      ],
      parent_card: {id: "card-parent-1", title: "Parent Card"},
      epic: {id: "epic-1", title: "Epic"}
    }
  end

  subject(:card) { described_class.new(card_data) }

  describe "#initialize" do
    it "assigns core identifiers" do
      expect(card.id).to eq("card-123")
      expect(card.type).to eq("card")
      expect(card.team_id).to eq("team-1")
      expect(card.project_id).to eq("project-1")
    end

    it "assigns content fields" do
      expect(card.title).to eq("Implement feature X")
      expect(card.content).to eq("Description here")
      expect(card.schema).to eq("1.0")
    end

    it "assigns status and priority" do
      expect(card.status).to eq("started")
      expect(card.priority).to eq(2)
      expect(card.estimate).to eq(5)
    end

    it "assigns location fields" do
      expect(card.board_id).to eq("board-1")
      expect(card.board_title).to eq("Sprint Board")
      expect(card.list_id).to eq("list-1")
      expect(card.list_title).to eq("In Progress")
      expect(card.list_color).to eq("yellow")
      expect(card.sprint_id).to eq("sprint-1")
    end

    it "assigns ownership fields" do
      expect(card.owner_id).to eq("user-1")
      expect(card.user_id).to eq("user-1")
      expect(card.user_id_updated).to eq("user-2")
    end

    it "assigns counts" do
      expect(card.total_comments).to eq(3)
      expect(card.total_files).to eq(2)
    end

    it "assigns flags" do
      expect(card.is_watching).to be true
      expect(card.is_bookmarked).to be false
      expect(card.archived_list).to be false
      expect(card.archived_board).to be false
    end
  end

  describe "#members" do
    it "returns Member objects" do
      members = card.members
      expect(members).to be_an(Array)
      expect(members.first).to be_a(Superthread::Objects::Member)
      expect(members.first.user_id).to eq("user-1")
      expect(members.first.role).to eq("admin")
    end

    it "returns empty array when no members" do
      card = described_class.new({})
      expect(card.members).to eq([])
    end
  end

  describe "#checklists" do
    it "returns Checklist objects" do
      checklists = card.checklists
      expect(checklists).to be_an(Array)
      expect(checklists.first).to be_a(Superthread::Objects::Checklist)
      expect(checklists.first.title).to eq("Tasks")
    end

    it "returns empty array when no checklists" do
      card = described_class.new({})
      expect(card.checklists).to eq([])
    end
  end

  describe "#tags" do
    it "returns Tag objects" do
      tags = card.tags
      expect(tags).to be_an(Array)
      expect(tags.first).to be_a(Superthread::Objects::Tag)
      expect(tags.first.name).to eq("bug")
    end

    it "returns empty array when no tags" do
      card = described_class.new({})
      expect(card.tags).to eq([])
    end
  end

  describe "#child_cards" do
    it "returns Card objects" do
      children = card.child_cards
      expect(children).to be_an(Array)
      expect(children.first).to be_a(described_class)
      expect(children.first.title).to eq("Subtask 1")
    end

    it "returns empty array when no child cards" do
      card = described_class.new({})
      expect(card.child_cards).to eq([])
    end
  end

  describe "#linked_cards" do
    it "returns LinkedCard objects" do
      linked = card.linked_cards
      expect(linked).to be_an(Array)
      expect(linked.first).to be_a(Superthread::Objects::LinkedCard)
      expect(linked.first.title).to eq("Related Card")
      expect(linked.first.linked_card_type).to eq("blocks")
    end

    it "returns empty array when no linked cards" do
      card = described_class.new({})
      expect(card.linked_cards).to eq([])
    end
  end

  describe "#parent_card" do
    it "returns parent card object when present" do
      parent = card.parent_card
      expect(parent).to be_a(Superthread::Object)
      expect(parent.title).to eq("Parent Card")
    end

    it "returns nil when no parent" do
      card = described_class.new({})
      expect(card.parent_card).to be_nil
    end
  end

  describe "#epic" do
    it "returns epic object when present" do
      epic = card.epic
      expect(epic).to be_a(Superthread::Object)
      expect(epic.title).to eq("Epic")
    end

    it "returns nil when no epic" do
      card = described_class.new({})
      expect(card.epic).to be_nil
    end
  end

  describe "#archived" do
    it "returns archive info when archived" do
      card = described_class.new(archived: {user_id: "user-1", time_archived: 1705400000000})
      archived = card.archived
      expect(archived).to be_a(Superthread::Object)
      expect(archived.user_id).to eq("user-1")
    end

    it "returns nil when not archived" do
      expect(card.archived).to be_nil
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      card = described_class.new(archived: {user_id: "user-1"})
      expect(card.archived?).to be true
    end

    it "returns false when not archived" do
      expect(card.archived?).to be false
    end
  end

  describe "#watching?" do
    it "returns true when watching" do
      expect(card.watching?).to be true
    end

    it "returns false when not watching" do
      card = described_class.new(is_watching: false)
      expect(card.watching?).to be false
    end

    it "returns false when is_watching is nil" do
      card = described_class.new({})
      expect(card.watching?).to be false
    end
  end

  describe "#bookmarked?" do
    it "returns true when bookmarked" do
      card = described_class.new(is_bookmarked: true)
      expect(card.bookmarked?).to be true
    end

    it "returns false when not bookmarked" do
      expect(card.bookmarked?).to be false
    end

    it "returns false when is_bookmarked is nil" do
      card = described_class.new({})
      expect(card.bookmarked?).to be false
    end
  end

  describe "#start_time" do
    it "converts start_date to Time" do
      expect(card.start_time).to be_a(Time)
      expect(card.start_time.year).to eq(2024)
    end

    it "returns nil when start_date is nil" do
      card = described_class.new({})
      expect(card.start_time).to be_nil
    end
  end

  describe "#due_time" do
    it "converts due_date to Time" do
      expect(card.due_time).to be_a(Time)
      expect(card.due_time.year).to eq(2024)
    end

    it "returns nil when due_date is nil" do
      card = described_class.new({})
      expect(card.due_time).to be_nil
    end
  end

  describe "#completed_time" do
    it "converts completed_date to Time" do
      card = described_class.new(completed_date: 1705916400000)
      expect(card.completed_time).to be_a(Time)
      expect(card.completed_time.year).to eq(2024)
    end

    it "returns nil when completed_date is nil" do
      expect(card.completed_time).to be_nil
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(card.created_at).to be_a(Time)
      expect(card.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      card = described_class.new({})
      expect(card.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(card.updated_at).to be_a(Time)
      expect(card.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      card = described_class.new({})
      expect(card.updated_at).to be_nil
    end
  end

  describe "#priority_name" do
    it "returns 'urgent' for priority 1" do
      card = described_class.new(priority: 1)
      expect(card.priority_name).to eq("urgent")
    end

    it "returns 'high' for priority 2" do
      expect(card.priority_name).to eq("high")
    end

    it "returns 'medium' for priority 3" do
      card = described_class.new(priority: 3)
      expect(card.priority_name).to eq("medium")
    end

    it "returns 'low' for priority 4" do
      card = described_class.new(priority: 4)
      expect(card.priority_name).to eq("low")
    end

    it "returns nil for unknown priority" do
      card = described_class.new(priority: 5)
      expect(card.priority_name).to be_nil
    end

    it "returns nil when priority is nil" do
      card = described_class.new({})
      expect(card.priority_name).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'card' type" do
      expect(Superthread::Object.object_types["card"]).to eq(described_class)
    end
  end
end

RSpec.describe Superthread::Objects::Member do
  let(:member_data) do
    {
      user_id: "user-123",
      role: "admin",
      assigned_date: 1705312200000
    }
  end

  subject(:member) { described_class.new(member_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(member.user_id).to eq("user-123")
      expect(member.role).to eq("admin")
      expect(member.assigned_date).to eq(1705312200000)
    end
  end

  describe "#assigned_at" do
    it "converts assigned_date to Time" do
      expect(member.assigned_at).to be_a(Time)
      expect(member.assigned_at.year).to eq(2024)
    end

    it "returns nil when assigned_date is nil" do
      member = described_class.new({})
      expect(member.assigned_at).to be_nil
    end
  end
end

RSpec.describe Superthread::Objects::LinkedCard do
  let(:linked_card_data) do
    {
      id: "card-456",
      title: "Related Card",
      linked_card_type: "blocks"
    }
  end

  subject(:linked_card) { described_class.new(linked_card_data) }

  describe "#initialize" do
    it "assigns linked_card_type" do
      expect(linked_card.linked_card_type).to eq("blocks")
    end

    it "inherits Card attributes" do
      expect(linked_card.id).to eq("card-456")
      expect(linked_card.title).to eq("Related Card")
    end
  end

  describe "#relationship" do
    it "returns linked_card_type as alias" do
      expect(linked_card.relationship).to eq("blocks")
    end
  end
end
