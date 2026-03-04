# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st sprints", :cli do
  describe "sprints list" do
    before do
      stub_resolve_space
      stub_api_get("test_workspace/sprints", response: ApiFixtures::Sprints::LIST, query: {project_id: "1"})
    end

    it "lists all sprints in a space" do
      result = run_cli("sprints", "list", "--space=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint 1")
      expect(result[:stdout]).to include("Sprint 2")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("sprints", "list", "--space=1")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |s| s["title"] }).to include("Sprint 1", "Sprint 2")
    end
  end

  describe "sprints get SPRINT_ID" do
    before do
      stub_resolve_space
      stub_api_get("test_workspace/sprints/sprint-1", response: ApiFixtures::Sprints::GET, query: {project_id: "1"})
    end

    it "displays sprint details" do
      result = run_cli("sprints", "get", "sprint-1", "--space=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint 1")
      expect(result[:stdout]).to include("sprint-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("sprints", "get", "sprint-1", "--space=1")

      expect(json["id"]).to eq("sprint-1")
      expect(json["title"]).to eq("Sprint 1")
    end
  end
end
