# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st search", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "search query SEARCH_TERM" do
    before do
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/search")
        .with(query: hash_including(q: "authentication"))
        .to_return(status: 200, body: ApiFixtures::Search::RESULTS.to_json,
          headers: {"Content-Type" => "application/json"})
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

  describe "search query with type filter" do
    before do
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/search")
        .with(query: hash_including(q: "authentication"))
        .to_return(status: 200, body: ApiFixtures::Search::RESULTS_TYPED.to_json,
          headers: {"Content-Type" => "application/json"})
    end

    it "filters by type" do
      result = run_cli("search", "query", "authentication", "--types=card,page")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Auth Module")
    end
  end
end
