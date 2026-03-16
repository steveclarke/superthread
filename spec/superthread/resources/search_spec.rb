# frozen_string_literal: true

require "spec_helper"

RSpec.describe Superthread::Resources::Search do
  include StubHelpers

  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#query" do
    it "returns search results" do
      stub_api_get("test_workspace/search",
        response: ApiFixtures::Search::RESULTS,
        query: {query: "auth"})

      results = client.search.query("test_workspace", query: "auth")

      expect(results.count).to eq(2)
      expect(results.first[:title]).to eq("Auth Module")
    end

    it "follows cursor for pagination" do
      page1 = {
        count: 2,
        cursor: "page2cursor",
        results: [{card: {id: "card-1", title: "Result 1"}}]
      }
      page2 = {
        count: 2,
        cursor: "",
        results: [{card: {id: "card-2", title: "Result 2"}}]
      }

      # Use to_return chaining to return page1 first, then page2
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/search")
        .with(query: hash_including("query" => "test"))
        .to_return(
          {status: 200, body: page1.to_json, headers: {"Content-Type" => "application/json"}},
          {status: 200, body: page2.to_json, headers: {"Content-Type" => "application/json"}}
        )

      results = client.search.query("test_workspace", query: "test")

      expect(results.count).to eq(2)
      expect(results.map { |r| r[:title] }).to eq(["Result 1", "Result 2"])
    end

    it "stops at limit" do
      page1 = {
        count: 3,
        cursor: "page2cursor",
        results: [
          {card: {id: "card-1", title: "Result 1"}},
          {card: {id: "card-2", title: "Result 2"}}
        ]
      }

      stub_api_get("test_workspace/search",
        response: page1,
        query: {query: "test"})

      results = client.search.query("test_workspace", query: "test", limit: 1)

      expect(results.count).to eq(1)
      expect(results.first[:title]).to eq("Result 1")
    end
  end
end
