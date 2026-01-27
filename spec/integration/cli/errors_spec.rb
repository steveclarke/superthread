# frozen_string_literal: true

require "spec_helper"

RSpec.describe "CLI error handling", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "404 Not Found" do
    it "displays friendly error message" do
      stub_api_error(:get, "test_workspace/cards/nonexistent", status: 404, error: "Card not found")

      result = run_cli("cards", "get", "nonexistent")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include("Card not found")
      expect(result[:stderr]).to include("suth cards list")
    end
  end

  describe "missing required options" do
    it "shows error for boards list without --space" do
      result = run_cli("boards", "list")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include("--space")
    end
  end

  describe "invalid commands" do
    it "shows help for unknown subcommand" do
      result = run_cli("cards", "unknown")

      expect(result[:exit_code]).to eq(1)
    end
  end
end
