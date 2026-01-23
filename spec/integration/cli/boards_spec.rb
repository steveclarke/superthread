# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st boards", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "boards list --space" do
    it "lists boards in a space", vcr: {cassette_name: "cli/boards_list"} do
      result = run_cli("boards", "list", "--space=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint Board")
      expect(result[:stdout]).to include("Backlog")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_list"} do
      json = cli_json("boards", "list", "--space=1")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first["title"]).to eq("Sprint Board")
    end
  end

  describe "boards get BOARD" do
    it "displays board details", vcr: {cassette_name: "cli/boards_get"} do
      result = run_cli("boards", "get", "10")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint Board")
      expect(result[:stdout]).to include("Current sprint tasks")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_get"} do
      json = cli_json("boards", "get", "10")

      expect(json["id"]).to eq("10")
      expect(json["title"]).to eq("Sprint Board")
      expect(json["lists"]).to be_an(Array)
      expect(json["lists"].length).to eq(3)
    end
  end

  describe "boards create" do
    it "creates a new board", vcr: {cassette_name: "cli/boards_create"} do
      result = run_cli("boards", "create",
        "--space=1",
        "--title=New Board",
        "--content=A new board for testing")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Board")
      expect(result[:stdout]).to include("board-new-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_create"} do
      json = cli_json("boards", "create",
        "--space=1",
        "--title=New Board",
        "--content=A new board for testing")

      expect(json["id"]).to eq("board-new-1")
      expect(json["title"]).to eq("New Board")
      expect(json["space_id"]).to eq("1")
    end
  end

  describe "boards update BOARD" do
    it "updates board attributes", vcr: {cassette_name: "cli/boards_update"} do
      result = run_cli("boards", "update", "10",
        "--title=Updated Sprint Board")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated Sprint Board")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_update"} do
      json = cli_json("boards", "update", "10",
        "--title=Updated Sprint Board")

      expect(json["id"]).to eq("10")
      expect(json["title"]).to eq("Updated Sprint Board")
    end
  end

  describe "boards delete BOARD" do
    it "deletes a board with --force", vcr: {cassette_name: "cli/boards_delete"} do
      result = run_cli("boards", "delete", "board-to-delete", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Board board-to-delete deleted")
    end
  end

  describe "boards duplicate BOARD" do
    it "duplicates a board", vcr: {cassette_name: "cli/boards_duplicate"} do
      result = run_cli("boards", "duplicate", "10",
        "--title=Copy of Sprint Board")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Copy of Sprint Board")
      expect(result[:stdout]).to include("board-dup-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_duplicate"} do
      json = cli_json("boards", "duplicate", "10",
        "--title=Copy of Sprint Board")

      expect(json["id"]).to eq("board-dup-1")
      expect(json["title"]).to eq("Copy of Sprint Board")
      expect(json["lists"]).to be_an(Array)
      expect(json["lists"].length).to eq(3)
    end
  end

  describe "boards list_create" do
    it "creates a list on a board", vcr: {cassette_name: "cli/boards_list_create"} do
      result = run_cli("boards", "list_create",
        "--board=10",
        "--title=Review")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Review")
      expect(result[:stdout]).to include("103")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_list_create"} do
      json = cli_json("boards", "list_create",
        "--board=10",
        "--title=Review")

      expect(json["id"]).to eq("103")
      expect(json["title"]).to eq("Review")
      expect(json["board_id"]).to eq("10")
    end
  end

  describe "boards list_update LIST_ID" do
    it "updates a list", vcr: {cassette_name: "cli/boards_list_update"} do
      result = run_cli("boards", "list_update", "100",
        "--title=Backlog")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Backlog")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/boards_list_update"} do
      json = cli_json("boards", "list_update", "100",
        "--title=Backlog")

      expect(json["id"]).to eq("100")
      expect(json["title"]).to eq("Backlog")
    end
  end

  describe "boards list_delete LIST_ID" do
    it "deletes a list with --force", vcr: {cassette_name: "cli/boards_list_delete"} do
      result = run_cli("boards", "list_delete", "103", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("List 103 deleted")
    end
  end
end
