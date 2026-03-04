# frozen_string_literal: true

RSpec.describe Superthread::Models::Page do
  it_behaves_like "archivable" do
    let(:model_class) { described_class }
  end

  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Project Overview" }
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
    let(:hash_symbol_value) { "Project Overview" }
    let(:hash_string_key) { "space_id" }
    let(:hash_string_value) { "space-789" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { page_data }
  end

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
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
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
end
