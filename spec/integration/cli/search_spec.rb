# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st search", :cli do
  describe "search query SEARCH_TERM" do
    before do
      stub_api_get("test_workspace/search", response: ApiFixtures::Search::RESULTS, query: {query: "authentication"})
    end

    it "searches across workspace" do
      result = run_cli("search", "query", "authentication")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
      expect(result[:stdout]).to include("Login Flow")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("search", "query", "authentication")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |r| r["title"] }).to include("Auth Module", "Login Flow")
    end
  end

  describe "search query with --limit 0" do
    before do
      stub_api_get("test_workspace/search", response: ApiFixtures::Search::RESULTS, query: {query: "test"})
    end

    it "shows all results with --limit 0" do
      result = run_cli("search", "query", "test", "--limit=0")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
      expect(result[:stdout]).to include("Login Flow")
    end
  end

  describe "search query with --status" do
    before do
      stub_api_get("test_workspace/search",
        response: ApiFixtures::Search::RESULTS_TYPED,
        query: {query: "auth"})
    end

    it "accepts status filter" do
      result = run_cli("search", "query", "auth", "--status=open,started")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
    end
  end

  describe "search query with --limit" do
    before do
      stub_api_get("test_workspace/search",
        response: ApiFixtures::Search::RESULTS,
        query: {query: "test"})
    end

    it "passes limit to resource" do
      result = run_cli("search", "query", "test", "--limit=10")

      expect(result[:exit_code]).to eq(0)
    end
  end

  describe "search query with type filter" do
    before do
      stub_api_get("test_workspace/search", response: ApiFixtures::Search::RESULTS_TYPED, query: {query: "authentication"})
    end

    it "filters by type" do
      result = run_cli("search", "query", "authentication", "--types=card,page")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
    end
  end
end
