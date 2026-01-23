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

  describe "boards get BOARD_ID" do
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
end
