# frozen_string_literal: true

RSpec.describe Superthread::Models::ChecklistItem do
  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Write specs" }
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
    let(:hash_symbol_value) { "Write specs" }
    let(:hash_string_key) { "checklist_id" }
    let(:hash_string_value) { "checklist-456" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { item_data }
  end

  let(:item_data) do
    {
      "id" => "item-123",
      "title" => "Write specs",
      "content" => "Write comprehensive specs",
      "checklist_id" => "checklist-456",
      "user_id" => "user-789",
      "checked" => true,
      "position" => 2,
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
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
end
