# frozen_string_literal: true

RSpec.describe Superthread::Models::Board do
  let(:board_data) do
    {
      "id" => "board-123",
      "type" => "board",
      "team_id" => "team-456",
      "space_id" => "space-789",
      "title" => "Sprint Board",
      "description" => "Board for sprint tasks",
      "user_id" => "user-001",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600,
      "lists" => [
        {"id" => "list-1", "title" => "To Do", "color" => "gray", "position" => 0},
        {"id" => "list-2", "title" => "In Progress", "color" => "blue", "position" => 1},
        {"id" => "list-3", "title" => "Done", "color" => "green", "position" => 2}
      ]
    }
  end

  subject(:board) { described_class.from_response(board_data) }

  describe ".from_response" do
    it "creates a board from hash data" do
      expect(board).to be_a(described_class)
      expect(board.id).to eq("board-123")
      expect(board.title).to eq("Sprint Board")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = board.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("board-123")
      expect(hash[:title]).to eq("Sprint Board")
    end
  end

  describe "#archived?" do
    it "returns false when not archived" do
      expect(board.archived?).to be false
    end

    it "returns true when archived" do
      archived_board = described_class.from_response(
        board_data.merge("archived" => {"user_id" => "user-1", "time_archived" => 1_705_312_200})
      )
      expect(archived_board.archived?).to be true
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(board.created_at).to be_a(Time)
      expect(board.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(board.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      board_without_times = described_class.from_response({"id" => "1"})
      expect(board_without_times.created_at).to be_nil
      expect(board_without_times.updated_at).to be_nil
    end
  end

  describe "nested lists" do
    it "parses lists as List objects" do
      expect(board.lists).to be_an(Array)
      expect(board.lists.length).to eq(3)
      expect(board.lists.first).to be_a(Superthread::Models::List)
    end

    it "preserves list data" do
      list = board.lists.first
      expect(list.id).to eq("list-1")
      expect(list.title).to eq("To Do")
      expect(list.color).to eq("gray")
      expect(list.position).to eq(0)
    end
  end

  describe "#to_s" do
    it "returns the board title" do
      expect(board.to_s).to eq("Sprint Board")
    end

    it "returns empty string when title is nil" do
      board_without_title = described_class.from_response({"id" => "1"})
      expect(board_without_title.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(board[:title]).to eq("Sprint Board")
      expect(board["space_id"]).to eq("space-789")
    end

    it "supports key? check" do
      expect(board.key?(:title)).to be true
      expect(board.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      board2 = described_class.from_response(board_data)
      expect(board).to eq(board2)
    end

    it "returns false for different boards" do
      board2 = described_class.from_response(board_data.merge("id" => "different"))
      expect(board).not_to eq(board2)
    end
  end
end
