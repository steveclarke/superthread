# frozen_string_literal: true

RSpec.describe Superthread::Models::Checklist do
  # Note: Checklist has custom to_s that shows progress, so no presentable shared example

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {
        time_created: :created_at,
        time_updated: :updated_at
      }
    end
  end

  let(:checklist_data) do
    {
      "id" => "checklist-123",
      "title" => "Requirements",
      "content" => "Checklist for requirements",
      "card_id" => "card-456",
      "user_id" => "user-789",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600,
      "items" => [
        {"id" => "item-1", "title" => "Write specs", "checked" => true},
        {"id" => "item-2", "title" => "Implement", "checked" => false},
        {"id" => "item-3", "title" => "Review", "checked" => true}
      ]
    }
  end

  subject(:checklist) { described_class.from_response(checklist_data) }

  describe ".from_response" do
    it "creates a checklist from hash data" do
      expect(checklist).to be_a(described_class)
      expect(checklist.id).to eq("checklist-123")
      expect(checklist.title).to eq("Requirements")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = checklist.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("checklist-123")
      expect(hash[:title]).to eq("Requirements")
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(checklist.created_at).to be_a(Time)
      expect(checklist.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(checklist.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      checklist_without_times = described_class.from_response({"id" => "1"})
      expect(checklist_without_times.created_at).to be_nil
      expect(checklist_without_times.updated_at).to be_nil
    end
  end

  describe "nested items" do
    it "parses items as ChecklistItem objects" do
      expect(checklist.items).to be_an(Array)
      expect(checklist.items.length).to eq(3)
      expect(checklist.items.first).to be_a(Superthread::Models::ChecklistItem)
    end

    it "preserves item data" do
      item = checklist.items.first
      expect(item.id).to eq("item-1")
      expect(item.title).to eq("Write specs")
      expect(item.checked?).to be true
    end
  end

  describe "#completed_count" do
    it "returns number of checked items" do
      expect(checklist.completed_count).to eq(2)
    end

    it "returns 0 for empty items" do
      empty_checklist = described_class.from_response({"id" => "1"})
      expect(empty_checklist.completed_count).to eq(0)
    end
  end

  describe "#total_count" do
    it "returns total number of items" do
      expect(checklist.total_count).to eq(3)
    end

    it "returns 0 for empty items" do
      empty_checklist = described_class.from_response({"id" => "1"})
      expect(empty_checklist.total_count).to eq(0)
    end
  end

  describe "#progress" do
    it "returns percentage complete" do
      expect(checklist.progress).to eq(66.7)
    end

    it "returns 0.0 for empty checklist" do
      empty_checklist = described_class.from_response({"id" => "1"})
      expect(empty_checklist.progress).to eq(0.0)
    end

    it "returns 100.0 for fully complete checklist" do
      complete_checklist = described_class.from_response({
        "id" => "1",
        "items" => [
          {"id" => "1", "title" => "Done", "checked" => true}
        ]
      })
      expect(complete_checklist.progress).to eq(100.0)
    end
  end

  describe "#complete?" do
    it "returns false when not all items are checked" do
      expect(checklist.complete?).to be false
    end

    it "returns true when all items are checked" do
      complete_checklist = described_class.from_response({
        "id" => "1",
        "items" => [
          {"id" => "1", "title" => "Done", "checked" => true}
        ]
      })
      expect(complete_checklist.complete?).to be true
    end

    it "returns false for empty checklist" do
      empty_checklist = described_class.from_response({"id" => "1"})
      expect(empty_checklist.complete?).to be false
    end
  end

  describe "#to_s" do
    it "returns title with progress" do
      expect(checklist.to_s).to eq("Requirements (2/3)")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(checklist[:title]).to eq("Requirements")
      expect(checklist["card_id"]).to eq("card-456")
    end

    it "supports key? check" do
      expect(checklist.key?(:title)).to be true
      expect(checklist.key?(:nonexistent)).to be false
    end
  end
end
