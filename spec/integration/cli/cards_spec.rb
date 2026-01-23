# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st cards", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "cards get CARD_ID" do
    it "displays card details", vcr: {cassette_name: "cli/cards_get"} do
      result = run_cli("cards", "get", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("started")
      expect(result[:stdout]).to include("In Progress")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_get"} do
      json = cli_json("cards", "get", "card-123")

      expect(json["id"]).to eq("card-123")
      expect(json["title"]).to eq("Implement feature X")
      expect(json["status"]).to eq("started")
      expect(json["priority"]).to eq(2)
      expect(json["members"]).to be_an(Array)
      expect(json["tags"]).to be_an(Array)
    end
  end

  describe "cards assigned USER_ID" do
    it "lists cards assigned to user", vcr: {cassette_name: "cli/cards_assigned"} do
      result = run_cli("cards", "assigned", "u123abc")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("Fix bug Y")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_assigned"} do
      json = cli_json("cards", "assigned", "u123abc")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |c| c["title"] }).to include("Implement feature X", "Fix bug Y")
    end
  end

  describe "cards tags" do
    it "lists available tags", vcr: {cassette_name: "cli/cards_tags"} do
      result = run_cli("cards", "tags")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("backend")
      expect(result[:stdout]).to include("frontend")
      expect(result[:stdout]).to include("bug")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_tags"} do
      json = cli_json("cards", "tags")

      expect(json).to be_an(Array)
      expect(json.length).to eq(3)
      expect(json.first).to have_key("name")
      expect(json.first).to have_key("color")
      expect(json.first).to have_key("total_cards")
    end
  end
end
