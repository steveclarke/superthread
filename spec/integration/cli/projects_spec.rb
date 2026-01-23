# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st projects", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "projects list" do
    it "lists all projects", vcr: {cassette_name: "cli/projects_list"} do
      result = run_cli("projects", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Q1 Roadmap")
      expect(result[:stdout]).to include("Mobile App")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/projects_list"} do
      json = cli_json("projects", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |p| p["title"] }).to include("Q1 Roadmap", "Mobile App")
    end
  end

  describe "projects get PROJECT_ID" do
    it "displays project details", vcr: {cassette_name: "cli/projects_get"} do
      result = run_cli("projects", "get", "proj-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Q1 Roadmap")
      expect(result[:stdout]).to include("proj-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/projects_get"} do
      json = cli_json("projects", "get", "proj-1")

      expect(json["id"]).to eq("proj-1")
      expect(json["title"]).to eq("Q1 Roadmap")
      expect(json["status"]).to eq("in_progress")
    end
  end

  describe "projects create" do
    it "creates a new project", vcr: {cassette_name: "cli/projects_create"} do
      result = run_cli("projects", "create",
        "--title=New Project",
        "--list=100")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Project")
      expect(result[:stdout]).to include("proj-new-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/projects_create"} do
      json = cli_json("projects", "create",
        "--title=New Project",
        "--list=100")

      expect(json["id"]).to eq("proj-new-1")
      expect(json["title"]).to eq("New Project")
    end
  end

  describe "projects update PROJECT_ID" do
    it "updates project attributes", vcr: {cassette_name: "cli/projects_update"} do
      result = run_cli("projects", "update", "proj-1", "--title=Updated Roadmap")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated Roadmap")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/projects_update"} do
      json = cli_json("projects", "update", "proj-1", "--title=Updated Roadmap")

      expect(json["id"]).to eq("proj-1")
      expect(json["title"]).to eq("Updated Roadmap")
    end
  end

  describe "projects delete PROJECT_ID" do
    it "deletes a project", vcr: {cassette_name: "cli/projects_delete"} do
      result = run_cli("projects", "delete", "proj-to-delete")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Project proj-to-delete deleted")
    end
  end

  describe "projects add_card PROJECT_ID CARD_ID" do
    it "links a card to a project", vcr: {cassette_name: "cli/projects_add_card"} do
      result = run_cli("projects", "add_card", "proj-1", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Linked card card-123 to project proj-1")
    end
  end

  describe "projects remove_card PROJECT_ID CARD_ID" do
    it "removes a card from a project", vcr: {cassette_name: "cli/projects_remove_card"} do
      result = run_cli("projects", "remove_card", "proj-1", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed card card-123 from project proj-1")
    end
  end
end
