# frozen_string_literal: true

RSpec.describe Superthread::Objects::Project do
  let(:project_data) do
    {
      id: "project-123",
      type: "project",
      team_id: "team-1",
      space_id: "space-1",
      title: "Q4 Planning",
      description: "Fourth quarter planning",
      status: "active",
      icon: "rocket",
      user_id: "user-1",
      start_date: 1705312200000,
      due_date: 1705916400000,
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:project) { described_class.new(project_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(project.id).to eq("project-123")
      expect(project.type).to eq("project")
      expect(project.team_id).to eq("team-1")
      expect(project.space_id).to eq("space-1")
      expect(project.title).to eq("Q4 Planning")
      expect(project.description).to eq("Fourth quarter planning")
      expect(project.status).to eq("active")
      expect(project.icon).to eq("rocket")
      expect(project.user_id).to eq("user-1")
      expect(project.start_date).to eq(1705312200000)
      expect(project.due_date).to eq(1705916400000)
      expect(project.time_created).to eq(1705312200000)
      expect(project.time_updated).to eq(1705398600000)
    end
  end

  describe "#archived" do
    it "returns archive info when archived" do
      project = described_class.new(archived: {user_id: "user-1", time_archived: 1705400000000})
      archived = project.archived
      expect(archived).to be_a(Superthread::Object)
      expect(archived.user_id).to eq("user-1")
    end

    it "returns nil when not archived" do
      expect(project.archived).to be_nil
    end
  end

  describe "#archived?" do
    it "returns true when archived" do
      project = described_class.new(archived: {user_id: "user-1"})
      expect(project.archived?).to be true
    end

    it "returns false when not archived" do
      expect(project.archived?).to be false
    end
  end

  describe "#start_time" do
    it "converts start_date to Time" do
      expect(project.start_time).to be_a(Time)
      expect(project.start_time.year).to eq(2024)
    end

    it "returns nil when start_date is nil" do
      project = described_class.new({})
      expect(project.start_time).to be_nil
    end
  end

  describe "#due_time" do
    it "converts due_date to Time" do
      expect(project.due_time).to be_a(Time)
      expect(project.due_time.year).to eq(2024)
    end

    it "returns nil when due_date is nil" do
      project = described_class.new({})
      expect(project.due_time).to be_nil
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(project.created_at).to be_a(Time)
      expect(project.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      project = described_class.new({})
      expect(project.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(project.updated_at).to be_a(Time)
      expect(project.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      project = described_class.new({})
      expect(project.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'project' type" do
      expect(Superthread::Object.object_types["project"]).to eq(described_class)
    end
  end
end
