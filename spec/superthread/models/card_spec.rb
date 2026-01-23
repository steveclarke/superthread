# frozen_string_literal: true

RSpec.describe Superthread::Models::Card do
  let(:card_data) do
    {
      "id" => "card-123",
      "title" => "Test Card",
      "status" => "started",
      "priority" => 1,
      "board_id" => "board-456",
      "board_title" => "Sprint Board",
      "list_id" => "list-789",
      "list_title" => "In Progress",
      "time_created" => 1_705_312_200_000,
      "time_updated" => 1_705_398_600_000,
      "is_watching" => true,
      "is_bookmarked" => false,
      "members" => [
        {"user_id" => "user-1", "role" => "assignee", "assigned_date" => 1_705_312_200_000}
      ],
      "tags" => [
        {"id" => "tag-1", "name" => "bug", "color" => "red"}
      ],
      "checklists" => [
        {
          "id" => "checklist-1",
          "title" => "Requirements",
          "items" => [
            {"id" => "item-1", "title" => "Write specs", "checked" => true},
            {"id" => "item-2", "title" => "Implement", "checked" => false}
          ]
        }
      ]
    }
  end

  subject(:card) { described_class.from_response(card_data) }

  describe ".from_response" do
    it "creates a card from hash data" do
      expect(card).to be_a(described_class)
      expect(card.id).to eq("card-123")
      expect(card.title).to eq("Test Card")
    end

    it "coerces types correctly" do
      expect(card.priority).to eq(1)
      expect(card.priority).to be_a(Integer)
      expect(card.time_created).to eq(1_705_312_200_000)
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = card.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("card-123")
      expect(hash[:title]).to eq("Test Card")
    end
  end

  describe "predicate methods" do
    it "returns watching status" do
      expect(card.watching?).to be true
    end

    it "returns bookmarked status" do
      expect(card.bookmarked?).to be false
    end

    it "returns archived status" do
      expect(card.archived?).to be false
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(card.created_at).to be_a(Time)
      expect(card.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(card.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      expect(card.due_time).to be_nil
    end
  end

  describe "#priority_name" do
    it "returns human-readable priority" do
      expect(card.priority_name).to eq("urgent")
    end

    it "returns nil for missing priority" do
      card_without_priority = described_class.from_response({"id" => "1"})
      expect(card_without_priority.priority_name).to be_nil
    end
  end

  describe "nested members" do
    it "parses members as Member objects" do
      expect(card.members).to be_an(Array)
      expect(card.members.first).to be_a(Superthread::Models::Member)
      expect(card.members.first.user_id).to eq("user-1")
      expect(card.members.first.role).to eq("assignee")
    end
  end

  describe "nested tags" do
    it "parses tags as Tag objects" do
      expect(card.tags).to be_an(Array)
      expect(card.tags.first).to be_a(Superthread::Models::Tag)
      expect(card.tags.first.name).to eq("bug")
      expect(card.tags.first.color).to eq("red")
    end
  end

  describe "nested checklists" do
    it "parses checklists as Checklist objects" do
      expect(card.checklists).to be_an(Array)
      expect(card.checklists.first).to be_a(Superthread::Models::Checklist)
      expect(card.checklists.first.title).to eq("Requirements")
    end

    it "parses checklist items" do
      checklist = card.checklists.first
      expect(checklist.items).to be_an(Array)
      expect(checklist.items.first).to be_a(Superthread::Models::ChecklistItem)
      expect(checklist.items.first.title).to eq("Write specs")
      expect(checklist.items.first.checked?).to be true
    end

    it "calculates checklist progress" do
      checklist = card.checklists.first
      expect(checklist.completed_count).to eq(1)
      expect(checklist.total_count).to eq(2)
      expect(checklist.progress).to eq(50.0)
      expect(checklist.complete?).to be false
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(card[:title]).to eq("Test Card")
      expect(card["status"]).to eq("started")
    end

    it "supports key? check" do
      expect(card.key?(:title)).to be true
      expect(card.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      card2 = described_class.from_response(card_data)
      expect(card).to eq(card2)
    end

    it "returns false for different cards" do
      card2 = described_class.from_response(card_data.merge("id" => "different"))
      expect(card).not_to eq(card2)
    end
  end
end
