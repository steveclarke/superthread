# frozen_string_literal: true

RSpec.describe Superthread::Models::Page do
  let(:page_data) do
    {
      "id" => "page-123",
      "type" => "page",
      "team_id" => "team-456",
      "space_id" => "space-789",
      "title" => "Project Overview",
      "content" => "<p>This is the project overview document.</p>",
      "icon" => "document",
      "user_id" => "user-001",
      "time_created" => 1_705_312_200_000,
      "time_updated" => 1_705_398_600_000
    }
  end

  subject(:page) { described_class.from_response(page_data) }

  describe ".from_response" do
    it "creates a page from hash data" do
      expect(page).to be_a(described_class)
      expect(page.id).to eq("page-123")
      expect(page.title).to eq("Project Overview")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = page.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("page-123")
      expect(hash[:title]).to eq("Project Overview")
    end
  end

  describe "#archived?" do
    it "returns false when not archived" do
      expect(page.archived?).to be false
    end

    it "returns true when archived" do
      archived_page = described_class.from_response(
        page_data.merge("archived" => {"user_id" => "user-1", "time_archived" => 1_705_312_200_000})
      )
      expect(archived_page.archived?).to be true
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(page.created_at).to be_a(Time)
      expect(page.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(page.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      page_without_times = described_class.from_response({"id" => "1"})
      expect(page_without_times.created_at).to be_nil
      expect(page_without_times.updated_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the page title" do
      expect(page.to_s).to eq("Project Overview")
    end

    it "returns empty string when title is nil" do
      page_without_title = described_class.from_response({"id" => "1"})
      expect(page_without_title.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(page[:title]).to eq("Project Overview")
      expect(page["space_id"]).to eq("space-789")
    end

    it "supports key? check" do
      expect(page.key?(:title)).to be true
      expect(page.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      page2 = described_class.from_response(page_data)
      expect(page).to eq(page2)
    end

    it "returns false for different pages" do
      page2 = described_class.from_response(page_data.merge("id" => "different"))
      expect(page).not_to eq(page2)
    end
  end
end
