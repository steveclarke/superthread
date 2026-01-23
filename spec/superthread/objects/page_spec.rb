# frozen_string_literal: true

RSpec.describe Superthread::Objects::Page do
  let(:page_data) do
    {
      id: "page-123",
      type: "page",
      team_id: "team-1",
      space_id: "space-1",
      title: "Project Overview",
      content: "<p>This project aims to...</p>",
      icon: "document",
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:page) { described_class.new(page_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(page.id).to eq("page-123")
      expect(page.type).to eq("page")
      expect(page.team_id).to eq("team-1")
      expect(page.space_id).to eq("space-1")
      expect(page.title).to eq("Project Overview")
      expect(page.content).to eq("<p>This project aims to...</p>")
      expect(page.icon).to eq("document")
      expect(page.user_id).to eq("user-1")
      expect(page.time_created).to eq(1705312200000)
      expect(page.time_updated).to eq(1705398600000)
    end
  end

  describe "#archived" do
    it "returns archive info when archived" do
      page = described_class.new(archived: {user_id: "user-1", time_archived: 1705400000000})
      archived = page.archived
      expect(archived).to be_a(Superthread::Object)
      expect(archived.user_id).to eq("user-1")
    end

    it "returns nil when not archived" do
      expect(page.archived).to be_nil
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      page = described_class.new(archived: {user_id: "user-1"})
      expect(page.archived?).to be true
    end

    it "returns false when not archived" do
      expect(page.archived?).to be false
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(page.created_at).to be_a(Time)
      expect(page.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      page = described_class.new({})
      expect(page.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(page.updated_at).to be_a(Time)
      expect(page.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      page = described_class.new({})
      expect(page.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'page' type" do
      expect(Superthread::Object.object_types["page"]).to eq(described_class)
    end
  end
end
