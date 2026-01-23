# frozen_string_literal: true

RSpec.describe Superthread::Objects::Sprint do
  let(:sprint_data) do
    {
      id: "sprint-123",
      type: "sprint",
      team_id: "team-1",
      space_id: "space-1",
      title: "Sprint 42",
      description: "The answer to everything",
      status: "active",
      start_date: 1705312200000,
      due_date: 1705916400000,
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:sprint) { described_class.new(sprint_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(sprint.id).to eq("sprint-123")
      expect(sprint.type).to eq("sprint")
      expect(sprint.team_id).to eq("team-1")
      expect(sprint.space_id).to eq("space-1")
      expect(sprint.title).to eq("Sprint 42")
      expect(sprint.description).to eq("The answer to everything")
      expect(sprint.status).to eq("active")
      expect(sprint.start_date).to eq(1705312200000)
      expect(sprint.due_date).to eq(1705916400000)
      expect(sprint.user_id).to eq("user-1")
      expect(sprint.time_created).to eq(1705312200000)
      expect(sprint.time_updated).to eq(1705398600000)
    end
  end

  describe "#active?" do
    it "returns true when status is active" do
      expect(sprint.active?).to be true
    end

    it "returns false when status is not active" do
      sprint = described_class.new(status: "complete")
      expect(sprint.active?).to be false
    end
  end

  describe "#complete?" do
    it "returns true when status is complete" do
      sprint = described_class.new(status: "complete")
      expect(sprint.complete?).to be true
    end

    it "returns false when status is not complete" do
      expect(sprint.complete?).to be false
    end
  end

  describe "#planned?" do
    it "returns true when status is planned" do
      sprint = described_class.new(status: "planned")
      expect(sprint.planned?).to be true
    end

    it "returns false when status is not planned" do
      expect(sprint.planned?).to be false
    end
  end

  describe "#start_time" do
    it "converts start_date to Time" do
      expect(sprint.start_time).to be_a(Time)
      expect(sprint.start_time.year).to eq(2024)
    end

    it "returns nil when start_date is nil" do
      sprint = described_class.new({})
      expect(sprint.start_time).to be_nil
    end
  end

  describe "#due_time" do
    it "converts due_date to Time" do
      expect(sprint.due_time).to be_a(Time)
      expect(sprint.due_time.year).to eq(2024)
    end

    it "returns nil when due_date is nil" do
      sprint = described_class.new({})
      expect(sprint.due_time).to be_nil
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(sprint.created_at).to be_a(Time)
      expect(sprint.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      sprint = described_class.new({})
      expect(sprint.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(sprint.updated_at).to be_a(Time)
      expect(sprint.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      sprint = described_class.new({})
      expect(sprint.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'sprint' type" do
      expect(Superthread::Object.object_types["sprint"]).to eq(described_class)
    end
  end
end
