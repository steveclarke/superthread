# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st search", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "search query SEARCH_TERM" do
    it "searches across workspace", vcr: {cassette_name: "cli/search_query"} do
      result = run_cli("search", "query", "authentication")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
      expect(result[:stdout]).to include("Login Flow")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/search_query"} do
      json = cli_json("search", "query", "authentication")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |r| r["title"] }).to include("Auth Module", "Login Flow")
    end

    it "filters by type", vcr: {cassette_name: "cli/search_query_types"} do
      result = run_cli("search", "query", "authentication", "--types=card,page")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
    end
  end
end
