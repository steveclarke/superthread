# frozen_string_literal: true

RSpec.describe Superthread::Objects::Tag do
  let(:tag_data) do
    {
      id: "tag-123",
      team_id: "team-1",
      project_id: "proj-1",
      name: "bug",
      slug: "bug",
      color: "#ff0000",
      total_cards: 17
    }
  end

  subject(:tag) { described_class.new(tag_data) }

  describe "#initialize" do
    it "sets id" do
      expect(tag.id).to eq("tag-123")
    end

    it "sets team_id" do
      expect(tag.team_id).to eq("team-1")
    end

    it "sets project_id" do
      expect(tag.project_id).to eq("proj-1")
    end

    it "sets name" do
      expect(tag.name).to eq("bug")
    end

    it "sets slug" do
      expect(tag.slug).to eq("bug")
    end

    it "sets color" do
      expect(tag.color).to eq("#ff0000")
    end

    it "sets total_cards" do
      expect(tag.total_cards).to eq(17)
    end
  end

  describe "#to_s" do
    it "returns the tag name" do
      expect(tag.to_s).to eq("bug")
    end

    it "returns nil for missing name" do
      tag = described_class.new({})
      expect(tag.to_s).to be_nil
    end
  end

  describe "type registration" do
    it "registers as 'tag' type" do
      expect(Superthread::Object.object_types["tag"]).to eq(described_class)
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(tag[:name]).to eq("bug")
    end

    it "supports string keys" do
      expect(tag["name"]).to eq("bug")
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      hash = tag.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:name]).to eq("bug")
    end
  end
end
