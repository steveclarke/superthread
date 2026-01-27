# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st lists", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "lists list --board" do
    before do
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_api_get("test_workspace/boards/10", response: ApiFixtures::Boards::GET)
    end

    it "lists columns on a board" do
      result = run_cli("lists", "list", "--board=10")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("To Do")
      expect(result[:stdout]).to include("In Progress")
      expect(result[:stdout]).to include("Done")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("lists", "list", "--board=10")

      expect(json).to be_an(Array)
      expect(json.length).to eq(3)
      expect(json.first["title"]).to eq("To Do")
    end
  end

  describe "lists create" do
    before do
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_api_post("test_workspace/lists", response: ApiFixtures::Boards::LIST_CREATE)
    end

    it "creates a list on a board" do
      result = run_cli("lists", "create", "--board=10", "--title=Review")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Review")
      expect(result[:stdout]).to include("103")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("lists", "create", "--board=10", "--title=Review")

      expect(json["id"]).to eq("103")
      expect(json["title"]).to eq("Review")
      expect(json["board_id"]).to eq("10")
    end
  end

  describe "lists update LIST_ID" do
    before do
      stub_api_patch("test_workspace/lists/100", response: ApiFixtures::Boards::LIST_UPDATE)
    end

    it "updates a list" do
      result = run_cli("lists", "update", "100", "--title=Backlog")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Backlog")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("lists", "update", "100", "--title=Backlog")

      expect(json["id"]).to eq("100")
      expect(json["title"]).to eq("Backlog")
    end
  end

  describe "lists delete LIST_ID" do
    before do
      stub_api_delete("test_workspace/lists/103")
    end

    it "deletes a list with -y" do
      result = run_cli("lists", "delete", "103", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("List 103 deleted")
    end
  end
end
