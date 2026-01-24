# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st workspaces", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "workspaces list" do
    before do
      stub_api_get("users/me", response: ApiFixtures::Workspaces::LIST)
    end

    it "lists available workspaces" do
      result = run_cli("workspaces", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("WORKSPACES")
      expect(result[:stdout]).to include("ws-123")
      expect(result[:stdout]).to include("My Team")
    end
  end

  describe "workspaces use WORKSPACE_ID" do
    it "sets the default workspace" do
      result = run_cli("workspaces", "use", "ws-456")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Default workspace set to: ws-456")
    end
  end

  describe "workspaces current" do
    it "shows current workspace when set via use command" do
      # Clear env var to test state file
      ENV.delete("SUPERTHREAD_WORKSPACE_ID")

      # First set a workspace
      run_cli("workspaces", "use", "ws-789")

      result = run_cli("workspaces", "current")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Current workspace: ws-789")
    end

    it "shows message when no workspace set" do
      # Clear env var to test "no workspace" state
      ENV.delete("SUPERTHREAD_WORKSPACE_ID")

      result = run_cli("workspaces", "current")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("No default workspace set")
    end

    it "shows workspace from environment variable" do
      result = run_cli("workspaces", "current")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Current workspace: test_workspace")
    end
  end
end
