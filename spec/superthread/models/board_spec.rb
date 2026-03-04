# frozen_string_literal: true

RSpec.describe Superthread::Models::Board do
  it_behaves_like "archivable" do
    let(:model_class) { described_class }
  end

  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Sprint Board" }
  end

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {
        time_created: :created_at,
        time_updated: :updated_at
      }
    end
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :title }
    let(:hash_symbol_value) { "Sprint Board" }
    let(:hash_string_key) { "team_id" }
    let(:hash_string_value) { "team-456" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { board_data }
  end

  let(:board_data) do
    {
      "id" => "board-123",
      "team_id" => "team-456",
      "title" => "Sprint Board",
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
end
