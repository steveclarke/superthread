# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st spaces", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "spaces list" do
    it "lists all spaces", vcr: {cassette_name: "cli/spaces_list"} do
      result = run_cli("spaces", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Engineering")
      expect(result[:stdout]).to include("Design")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/spaces_list"} do
      json = cli_json("spaces", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |s| s["title"] }).to include("Engineering", "Design")
    end
  end

  describe "spaces get SPACE_ID" do
    it "displays space details", vcr: {cassette_name: "cli/spaces_get"} do
      result = run_cli("spaces", "get", "1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Engineering")
      expect(result[:stdout]).to include("Engineering team space")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/spaces_get"} do
      json = cli_json("spaces", "get", "1")

      expect(json["id"]).to eq("1")
      expect(json["title"]).to eq("Engineering")
      expect(json["description"]).to eq("Engineering team space")
    end
  end
end
