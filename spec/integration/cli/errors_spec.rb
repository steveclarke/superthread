# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CLI error handling", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "404 Not Found" do
    it "displays friendly error message", vcr: {cassette_name: "cli/not_found"} do
      result = run_cli("cards", "get", "nonexistent")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stdout]).to include("Not found")
    end
  end

  describe "missing required options" do
    it "shows error for boards list without --space-id" do
      result = run_cli("boards", "list")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include("--space-id")
    end
  end

  describe "invalid commands" do
    it "shows help for unknown subcommand" do
      result = run_cli("cards", "unknown")

      expect(result[:exit_code]).to eq(1)
    end
  end
end
