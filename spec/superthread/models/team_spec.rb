# frozen_string_literal: true

RSpec.describe Superthread::Models::Team do
  let(:team_data) do
    {
      id: "team-123",
      team_name: "Engineering",
      sub_domain: "eng",
      role: "admin",
      status: "active",
      creator_user_id: "user-1",
      subscription_plan_id: "plan-1",
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:team) { described_class.from_response(team_data) }

  describe ".from_response" do
    it "creates a team from hash data" do
      expect(team.id).to eq("team-123")
      expect(team.team_name).to eq("Engineering")
      expect(team.role).to eq("admin")
    end
  end

  describe "#name" do
    it "returns team_name" do
      expect(team.name).to eq("Engineering")
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(team.created_at).to be_a(Time)
      expect(team.created_at.year).to eq(2024)
    end

    it "returns nil for missing time_created" do
      team = described_class.from_response({})
      expect(team.created_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the team name" do
      expect(team.to_s).to eq("Engineering")
    end

    it "returns empty string when team_name is nil" do
      team = described_class.from_response({})
      expect(team.to_s).to eq("")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = team.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("team-123")
    end
  end
end
