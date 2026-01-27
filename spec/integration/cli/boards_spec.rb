# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st boards", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "boards list --space" do
    before do
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/boards")
        .with(query: hash_including(project_id: "1"))
        .to_return(status: 200, body: ApiFixtures::Boards::LIST.to_json,
          headers: {"Content-Type" => "application/json"})
    end

    it "lists boards in a space" do
      result = run_cli("boards", "list", "--space=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint Board")
      expect(result[:stdout]).to include("Backlog")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("boards", "list", "--space=1")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first["title"]).to eq("Sprint Board")
    end
  end

  describe "boards get BOARD" do
    before do
      stub_api_get("test_workspace/boards/10", response: ApiFixtures::Boards::GET)
    end

    it "displays board details" do
      result = run_cli("boards", "get", "10")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint Board")
      expect(result[:stdout]).to include("10")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("boards", "get", "10")

      expect(json["id"]).to eq("10")
      expect(json["title"]).to eq("Sprint Board")
      expect(json["lists"]).to be_an(Array)
      expect(json["lists"].length).to eq(3)
    end
  end

  describe "boards create" do
    before do
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_api_post("test_workspace/boards", response: ApiFixtures::Boards::CREATE)
    end

    it "creates a new board" do
      result = run_cli("boards", "create",
        "--space=1",
        "--title=New Board",
        "--description=A new board for testing")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Board")
      expect(result[:stdout]).to include("board-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("boards", "create",
        "--space=1",
        "--title=New Board",
        "--description=A new board for testing")

      expect(json["id"]).to eq("board-new-1")
      expect(json["title"]).to eq("New Board")
    end
  end

  describe "boards update BOARD" do
    before do
      stub_api_patch("test_workspace/boards/10", response: ApiFixtures::Boards::UPDATE)
    end

    it "updates board attributes" do
      result = run_cli("boards", "update", "10",
        "--title=Updated Sprint Board")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated Sprint Board")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("boards", "update", "10",
        "--title=Updated Sprint Board")

      expect(json["id"]).to eq("10")
      expect(json["title"]).to eq("Updated Sprint Board")
    end
  end

  describe "boards delete BOARD" do
    before do
      stub_api_get("test_workspace/boards/board-to-delete", response: ApiFixtures::Boards::DELETE)
      stub_api_delete("test_workspace/boards/board-to-delete")
    end

    it "deletes a board with -y" do
      result = run_cli("boards", "delete", "board-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Board 'Board to Delete' deleted")
    end
  end

  describe "boards duplicate BOARD" do
    before do
      # resolve_space tries name lookup first, so stub the list endpoint
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_api_post("test_workspace/boards/10/copy", response: ApiFixtures::Boards::DUPLICATE)
    end

    it "duplicates a board" do
      result = run_cli("boards", "duplicate", "10",
        "--space=1",
        "--title=Copy of Sprint Board")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Copy of Sprint Board")
      expect(result[:stdout]).to include("board-dup-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("boards", "duplicate", "10",
        "--space=1",
        "--title=Copy of Sprint Board")

      expect(json["id"]).to eq("board-dup-1")
      expect(json["title"]).to eq("Copy of Sprint Board")
      expect(json["lists"]).to be_an(Array)
      expect(json["lists"].length).to eq(3)
    end
  end
end
