# frozen_string_literal: true

RSpec.describe Superthread::Models::List do
  it_behaves_like "archivable" do
    let(:model_class) { described_class }
  end

  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "In Progress" }
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
    let(:hash_symbol_value) { "In Progress" }
    let(:hash_string_key) { "color" }
    let(:hash_string_value) { "blue" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { list_data }
  end

  let(:list_data) do
    {
      "id" => "list-123",
      "type" => "list",
      "board_id" => "board-456",
      "title" => "In Progress",
      "color" => "blue",
      "position" => 1,
      "user_id" => "user-789",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
    }
  end

  subject(:list) { described_class.from_response(list_data) }

  describe ".from_response" do
    it "creates a list from hash data" do
      expect(list).to be_a(described_class)
      expect(list.id).to eq("list-123")
      expect(list.title).to eq("In Progress")
    end

    it "coerces types correctly" do
      expect(list.position).to eq(1)
      expect(list.position).to be_a(Integer)
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = list.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("list-123")
      expect(hash[:title]).to eq("In Progress")
    end
  end
end
