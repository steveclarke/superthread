# frozen_string_literal: true

RSpec.describe Superthread::Objects::Board do
  let(:board_data) do
    {
      id: "board-123",
      type: "board",
      team_id: "team-1",
      space_id: "space-1",
      title: "Sprint Backlog",
      description: "Current sprint work",
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000,
      lists: [
        {id: "list-1", title: "To Do", color: "blue", position: 0},
        {id: "list-2", title: "In Progress", color: "yellow", position: 1}
      ]
    }
  end

  subject(:board) { described_class.new(board_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(board.id).to eq("board-123")
      expect(board.type).to eq("board")
      expect(board.team_id).to eq("team-1")
      expect(board.space_id).to eq("space-1")
      expect(board.title).to eq("Sprint Backlog")
      expect(board.description).to eq("Current sprint work")
      expect(board.user_id).to eq("user-1")
      expect(board.time_created).to eq(1705312200000)
      expect(board.time_updated).to eq(1705398600000)
    end
  end

  describe "#lists" do
    it "returns List objects" do
      lists = board.lists
      expect(lists).to be_an(Array)
      expect(lists.length).to eq(2)
      expect(lists.first).to be_a(Superthread::Objects::List)
      expect(lists.first.title).to eq("To Do")
    end

    it "returns empty array when no lists" do
      board = described_class.new({})
      expect(board.lists).to eq([])
    end

    it "memoizes the result" do
      lists1 = board.lists
      lists2 = board.lists
      expect(lists1).to equal(lists2)
    end
  end

  describe "#archived" do
    it "returns archive info when archived" do
      board = described_class.new(archived: {user_id: "user-1", time_archived: 1705400000000})
      archived = board.archived
      expect(archived).to be_a(Superthread::Object)
      expect(archived.user_id).to eq("user-1")
    end

    it "returns nil when not archived" do
      expect(board.archived).to be_nil
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      board = described_class.new(archived: {user_id: "user-1"})
      expect(board.archived?).to be true
    end

    it "returns false when not archived" do
      expect(board.archived?).to be false
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(board.created_at).to be_a(Time)
      expect(board.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      board = described_class.new({})
      expect(board.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(board.updated_at).to be_a(Time)
      expect(board.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      board = described_class.new({})
      expect(board.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'board' type" do
      expect(Superthread::Object.object_types["board"]).to eq(described_class)
    end
  end
end

RSpec.describe Superthread::Objects::List do
  let(:list_data) do
    {
      id: "list-123",
      type: "list",
      board_id: "board-1",
      title: "To Do",
      color: "blue",
      position: 0,
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:list) { described_class.new(list_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(list.id).to eq("list-123")
      expect(list.type).to eq("list")
      expect(list.board_id).to eq("board-1")
      expect(list.title).to eq("To Do")
      expect(list.color).to eq("blue")
      expect(list.position).to eq(0)
      expect(list.user_id).to eq("user-1")
      expect(list.time_created).to eq(1705312200000)
      expect(list.time_updated).to eq(1705398600000)
    end
  end

  describe "#archived" do
    it "returns archive info when archived" do
      list = described_class.new(archived: {user_id: "user-1", time_archived: 1705400000000})
      archived = list.archived
      expect(archived).to be_a(Superthread::Object)
      expect(archived.user_id).to eq("user-1")
    end

    it "returns nil when not archived" do
      expect(list.archived).to be_nil
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      list = described_class.new(archived: {user_id: "user-1"})
      expect(list.archived?).to be true
    end

    it "returns false when not archived" do
      expect(list.archived?).to be false
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(list.created_at).to be_a(Time)
      expect(list.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      list = described_class.new({})
      expect(list.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(list.updated_at).to be_a(Time)
      expect(list.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      list = described_class.new({})
      expect(list.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'list' type" do
      expect(Superthread::Object.object_types["list"]).to eq(described_class)
    end
  end
end
