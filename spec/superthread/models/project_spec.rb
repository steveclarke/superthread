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

  describe "#archived?" do
    it "returns false when not archived" do
      expect(project.archived?).to be false
    end

    it "returns true when archived" do
      archived_project = described_class.from_response(
        project_data.merge("archived" => {"user_id" => "user-1", "time_archived" => 1_705_312_200})
      )
      expect(archived_project.archived?).to be true
    end
  end

  describe "date helpers" do
    it "converts start_date to Time" do
      expect(project.start_time).to be_a(Time)
      expect(project.start_time.year).to eq(2024)
    end

    it "converts due_date to Time" do
      expect(project.due_time).to be_a(Time)
      expect(project.due_time.year).to eq(2024)
    end

    it "returns nil for missing dates" do
      project_without_dates = described_class.from_response({"id" => "1"})
      expect(project_without_dates.start_time).to be_nil
      expect(project_without_dates.due_time).to be_nil
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(project.created_at).to be_a(Time)
      expect(project.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(project.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      project_without_times = described_class.from_response({"id" => "1"})
      expect(project_without_times.created_at).to be_nil
      expect(project_without_times.updated_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the project title" do
      expect(project.to_s).to eq("Q4 Planning")
    end

    it "returns empty string when title is nil" do
      project_without_title = described_class.from_response({"id" => "1"})
      expect(project_without_title.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(project[:title]).to eq("Q4 Planning")
      expect(project["status"]).to eq("active")
    end

    it "supports key? check" do
      expect(project.key?(:title)).to be true
      expect(project.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      project2 = described_class.from_response(project_data)
      expect(project).to eq(project2)
    end

    it "returns false for different projects" do
      project2 = described_class.from_response(project_data.merge("id" => "different"))
      expect(project).not_to eq(project2)
    end
  end
end
