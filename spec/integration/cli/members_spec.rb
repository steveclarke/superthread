# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st members", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "members list" do
    before do
      stub_api_get("teams/test_workspace/members", response: ApiFixtures::Users::MEMBERS)
    end

    it "lists workspace members" do
      result = run_cli("members", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Test User")
      expect(result[:stdout]).to include("Another User")
      expect(result[:stdout]).to include("owner")
      expect(result[:stdout]).to include("member")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("members", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first).to have_key("display_name")
    end
  end
end
