# frozen_string_literal: true

RSpec.describe Superthread::Models::Tag do
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

  describe "#to_s" do
    it "returns the tag name" do
      expect(tag.to_s).to eq("bug")
    end

    it "returns empty string when name is nil" do
      tag_without_name = described_class.from_response({"id" => "1"})
      expect(tag_without_name.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(tag[:name]).to eq("bug")
      expect(tag["color"]).to eq("red")
    end

    it "supports key? check" do
      expect(tag.key?(:name)).to be true
      expect(tag.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      tag2 = described_class.from_response(tag_data)
      expect(tag).to eq(tag2)
    end

    it "returns false for different tags" do
      tag2 = described_class.from_response(tag_data.merge("id" => "different"))
      expect(tag).not_to eq(tag2)
    end
  end
end
