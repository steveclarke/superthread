# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st users", :cli do
  before do
    # Set up test configuration
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "users me" do
    it "displays current user info", vcr: {cassette_name: "cli/users_me"} do
      result = run_cli("users", "me")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Display name")
      expect(result[:stdout]).to include("Test User")
      expect(result[:stdout]).to include("Email")
      expect(result[:stdout]).to include("test@example.com")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/users_me"} do
      json = cli_json("users", "me")

      expect(json).to have_key("display_name")
      expect(json["display_name"]).to eq("Test User")
      expect(json["email"]).to eq("test@example.com")
    end
  end

  describe "users members" do
    it "lists workspace members", vcr: {cassette_name: "cli/users_members"} do
      result = run_cli("users", "members")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Test User")
      expect(result[:stdout]).to include("Another User")
      expect(result[:stdout]).to include("owner")
      expect(result[:stdout]).to include("member")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/users_members"} do
      json = cli_json("users", "members")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first).to have_key("display_name")
    end
  end
end
