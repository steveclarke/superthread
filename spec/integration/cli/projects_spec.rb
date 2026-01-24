# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st projects", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "projects list" do
    before do
      stub_api_get("test_workspace/epics", response: ApiFixtures::Projects::LIST)
    end

    it "lists all projects" do
      result = run_cli("projects", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Q1 Roadmap")
      expect(result[:stdout]).to include("Mobile App")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("projects", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |p| p["title"] }).to include("Q1 Roadmap", "Mobile App")
    end
  end

  describe "projects get PROJECT_ID" do
    before do
      stub_api_get("test_workspace/epics/proj-1", response: ApiFixtures::Projects::GET)
    end

    it "displays project details" do
      result = run_cli("projects", "get", "proj-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Q1 Roadmap")
      expect(result[:stdout]).to include("proj-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("projects", "get", "proj-1")

      expect(json["id"]).to eq("proj-1")
      expect(json["title"]).to eq("Q1 Roadmap")
      expect(json["status"]).to eq("in_progress")
    end
  end

  describe "projects create" do
    before do
      stub_api_post("test_workspace/epics", response: ApiFixtures::Projects::CREATE)
    end

    it "creates a new project" do
      result = run_cli("projects", "create",
        "--title=New Project",
        "--list=100")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Project")
      expect(result[:stdout]).to include("proj-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("projects", "create",
        "--title=New Project",
        "--list=100")

      expect(json["id"]).to eq("proj-new-1")
      expect(json["title"]).to eq("New Project")
    end
  end

  describe "projects update PROJECT_ID" do
    before do
      stub_api_patch("test_workspace/epics/proj-1", response: ApiFixtures::Projects::UPDATE)
    end

    it "updates project attributes" do
      result = run_cli("projects", "update", "proj-1", "--title=Updated Roadmap")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated Roadmap")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("projects", "update", "proj-1", "--title=Updated Roadmap")

      expect(json["id"]).to eq("proj-1")
      expect(json["title"]).to eq("Updated Roadmap")
    end
  end

  describe "projects delete PROJECT_ID" do
    before do
      stub_api_delete("test_workspace/epics/proj-to-delete")
    end

    it "deletes a project" do
      result = run_cli("projects", "delete", "proj-to-delete")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Project proj-to-delete deleted")
    end
  end

  describe "projects add_card PROJECT_ID CARD_ID" do
    before do
      stub_api_post("test_workspace/epics/proj-1/cards/card-123", response: ApiFixtures::SUCCESS)
    end

    it "links a card to a project" do
      result = run_cli("projects", "add_card", "proj-1", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Linked card card-123 to project proj-1")
    end
  end

  describe "projects remove_card PROJECT_ID CARD_ID" do
    before do
      stub_api_delete("test_workspace/epics/proj-1/cards/card-123")
    end

    it "removes a card from a project" do
      result = run_cli("projects", "remove_card", "proj-1", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed card card-123 from project proj-1")
    end
  end
end
