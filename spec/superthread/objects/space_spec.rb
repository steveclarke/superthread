# frozen_string_literal: true

RSpec.describe Superthread::Objects::Space do
  let(:space_data) do
    {
      id: "space-123",
      type: "space",
      team_id: "team-1",
      title: "Engineering",
      description: "Engineering team space",
      icon: "gear",
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000,
      members: [
        {user_id: "user-1", role: "admin"},
        {user_id: "user-2", role: "member"}
      ]
    }
  end

  subject(:space) { described_class.new(space_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(space.id).to eq("space-123")
      expect(space.type).to eq("space")
      expect(space.team_id).to eq("team-1")
      expect(space.title).to eq("Engineering")
      expect(space.description).to eq("Engineering team space")
      expect(space.icon).to eq("gear")
      expect(space.user_id).to eq("user-1")
      expect(space.time_created).to eq(1705312200000)
      expect(space.time_updated).to eq(1705398600000)
    end
  end

  describe "#members" do
    it "returns Member objects" do
      members = space.members
      expect(members).to be_an(Array)
      expect(members.length).to eq(2)
      expect(members.first).to be_a(Superthread::Objects::Member)
      expect(members.first.user_id).to eq("user-1")
      expect(members.first.role).to eq("admin")
    end

    it "returns empty array when no members" do
      space = described_class.new({})
      expect(space.members).to eq([])
    end

    it "memoizes the result" do
      members1 = space.members
      members2 = space.members
      expect(members1).to equal(members2)
    end
  end

  describe "#archived" do
    it "returns archive info when archived" do
      space = described_class.new(archived: {user_id: "user-1", time_archived: 1705400000000})
      archived = space.archived
      expect(archived).to be_a(Superthread::Object)
      expect(archived.user_id).to eq("user-1")
    end

    it "returns nil when not archived" do
      expect(space.archived).to be_nil
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      space = described_class.new(archived: {user_id: "user-1"})
      expect(space.archived?).to be true
    end

    it "returns false when not archived" do
      expect(space.archived?).to be false
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(space.created_at).to be_a(Time)
      expect(space.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      space = described_class.new({})
      expect(space.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(space.updated_at).to be_a(Time)
      expect(space.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      space = described_class.new({})
      expect(space.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'space' type" do
      expect(Superthread::Object.object_types["space"]).to eq(described_class)
    end
  end
end
