# frozen_string_literal: true

RSpec.describe Superthread::Models::Project do
  it_behaves_like "archivable" do
    let(:model_class) { described_class }
  end

  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Q4 Planning" }
  end

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {
        time_created: :created_at,
        time_updated: :updated_at,
        start_date: :start_time,
        due_date: :due_time
      }
    end
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :title }
    let(:hash_symbol_value) { "Q4 Planning" }
    let(:hash_string_key) { "status" }
    let(:hash_string_value) { "active" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { project_data }
  end

  let(:project_data) do
    {
      "id" => "project-123",
      "type" => "project",
      "team_id" => "team-456",
      "space_id" => "space-789",
      "title" => "Q4 Planning",
      "description" => "Planning for Q4 initiatives",
      "status" => "active",
      "icon" => "rocket",
      "user_id" => "user-001",
      "start_date" => 1_705_312_200,
      "due_date" => 1_707_990_600,
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
    }
  end

  subject(:project) { described_class.from_response(project_data) }

  describe ".from_response" do
    it "creates a project from hash data" do
      expect(project).to be_a(described_class)
      expect(project.id).to eq("project-123")
      expect(project.title).to eq("Q4 Planning")
      expect(project.status).to eq("active")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = project.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("project-123")
      expect(hash[:title]).to eq("Q4 Planning")
    end
  end
end
