# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st sprints", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "sprints list" do
    before do
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/sprints")
        .with(query: hash_including(project_id: "1"))
        .to_return(status: 200, body: ApiFixtures::Sprints::LIST.to_json,
          headers: {"Content-Type" => "application/json"})
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
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/sprints/sprint-1")
        .with(query: hash_including(project_id: "1"))
        .to_return(status: 200, body: ApiFixtures::Sprints::GET.to_json,
          headers: {"Content-Type" => "application/json"})
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
