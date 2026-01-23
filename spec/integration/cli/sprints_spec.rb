# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st sprints", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "sprints list" do
    it "lists all sprints in a space", vcr: {cassette_name: "cli/sprints_list"} do
      result = run_cli("sprints", "list", "--space=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint 1")
      expect(result[:stdout]).to include("Sprint 2")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/sprints_list"} do
      json = cli_json("sprints", "list", "--space=1")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |s| s["title"] }).to include("Sprint 1", "Sprint 2")
    end
  end

  describe "sprints get SPRINT_ID" do
    it "displays sprint details", vcr: {cassette_name: "cli/sprints_get"} do
      result = run_cli("sprints", "get", "sprint-1", "--space=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint 1")
      expect(result[:stdout]).to include("sprint-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/sprints_get"} do
      json = cli_json("sprints", "get", "sprint-1", "--space=1")

      expect(json["id"]).to eq("sprint-1")
      expect(json["title"]).to eq("Sprint 1")
      expect(json["status"]).to eq("active")
    end
  end
end
