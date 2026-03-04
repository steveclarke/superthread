# frozen_string_literal: true

RSpec.describe Superthread::Models::Tag do
  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :name }
    let(:presentation_value) { "bug" }
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :name }
    let(:hash_symbol_value) { "bug" }
    let(:hash_string_key) { "color" }
    let(:hash_string_value) { "red" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { tag_data }
  end

  let(:tag_data) do
    {
      "id" => "tag-123",
      "team_id" => "team-456",
      "project_id" => "project-789",
      "name" => "bug",
      "slug" => "bug",
      "color" => "red",
      "total_cards" => 17
    }
  end

  subject(:tag) { described_class.from_response(tag_data) }

  describe ".from_response" do
    it "creates a tag from hash data" do
      expect(tag).to be_a(described_class)
      expect(tag.id).to eq("tag-123")
      expect(tag.name).to eq("bug")
      expect(tag.color).to eq("red")
    end

    it "coerces types correctly" do
      expect(tag.total_cards).to eq(17)
      expect(tag.total_cards).to be_a(Integer)
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = tag.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("tag-123")
      expect(hash[:name]).to eq("bug")
    end
  end
end
