# frozen_string_literal: true

RSpec.describe Superthread::Models::ChecklistItem do
  let(:item_data) do
    {
      "id" => "item-123",
      "title" => "Write specs",
      "content" => "Write comprehensive specs",
      "checklist_id" => "checklist-456",
      "user_id" => "user-789",
      "checked" => true,
      "time_created" => 1_705_312_200_000,
      "time_updated" => 1_705_398_600_000
    }
  end

  subject(:item) { described_class.from_response(item_data) }

  describe ".from_response" do
    it "creates an item from hash data" do
      expect(item).to be_a(described_class)
      expect(item.id).to eq("item-123")
      expect(item.title).to eq("Write specs")
    end

    it "coerces boolean correctly" do
      expect(item.checked).to be true
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = item.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("item-123")
      expect(hash[:title]).to eq("Write specs")
    end
  end

  describe "#checked?" do
    it "returns true when checked" do
      expect(item.checked?).to be true
    end

    it "returns false when not checked" do
      unchecked_item = described_class.from_response(item_data.merge("checked" => false))
      expect(unchecked_item.checked?).to be false
    end

    it "returns false when checked is nil" do
      item_without_checked = described_class.from_response({"id" => "1"})
      expect(item_without_checked.checked?).to be false
    end
  end

  describe "#complete?" do
    it "is an alias for checked?" do
      expect(item.complete?).to eq(item.checked?)
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(item.created_at).to be_a(Time)
      expect(item.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(item.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      item_without_times = described_class.from_response({"id" => "1"})
      expect(item_without_times.created_at).to be_nil
      expect(item_without_times.updated_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the title" do
      expect(item.to_s).to eq("Write specs")
    end

    it "returns empty string when title is nil" do
      item_without_title = described_class.from_response({"id" => "1"})
      expect(item_without_title.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(item[:title]).to eq("Write specs")
      expect(item["checklist_id"]).to eq("checklist-456")
    end

    it "supports key? check" do
      expect(item.key?(:title)).to be true
      expect(item.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      item2 = described_class.from_response(item_data)
      expect(item).to eq(item2)
    end

    it "returns false for different items" do
      item2 = described_class.from_response(item_data.merge("id" => "different"))
      expect(item).not_to eq(item2)
    end
  end
end
