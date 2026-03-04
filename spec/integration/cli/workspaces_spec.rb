# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st workspaces", :cli do
  before do
    ENV.delete("SUPERTHREAD_WORKSPACE_ID")
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

  describe "workspaces use WORKSPACE" do
    # Need to set up an account first since workspace is saved per-account
    let(:config_path) { File.join(ENV["XDG_CONFIG_HOME"], "superthread", "config.yaml") }

    before do
      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, YAML.dump({
        "accounts" => {"test" => {"api_key" => "test_key"}}
      }))

      state_path = File.join(ENV["XDG_STATE_HOME"], "superthread", "context.yaml")
      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(state_path, YAML.dump({"current_account" => "test"}))

      stub_api_get("users/me", response: ApiFixtures::Workspaces::LIST)
    end

    it "sets the default workspace by ID" do
      result = run_cli("workspaces", "use", "ws-456")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Default workspace set to: Other Team (ws-456)")
    end

    it "sets the default workspace by name" do
      result = run_cli("workspaces", "use", "My Team")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Default workspace set to: My Team (ws-123)")
    end

    it "shows error for unknown workspace" do
      result = run_cli("workspaces", "use", "unknown")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Workspace 'unknown' not found")
    end
  end

  describe "workspaces current" do
    it "shows current workspace from environment variable" do
      ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"

      result = run_cli("workspaces", "current")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Current workspace: test_workspace")
    end

    it "shows message when no workspace set" do
      ENV.delete("SUPERTHREAD_WORKSPACE_ID")

      result = run_cli("workspaces", "current")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("No default workspace set")
    end

    context "with account configured" do
      let(:config_path) { File.join(ENV["XDG_CONFIG_HOME"], "superthread", "config.yaml") }
      let(:state_path) { File.join(ENV["XDG_STATE_HOME"], "superthread", "context.yaml") }

      before do
        ENV.delete("SUPERTHREAD_WORKSPACE_ID")

        FileUtils.mkdir_p(File.dirname(config_path))
        File.write(config_path, YAML.dump({
          "accounts" => {"test" => {"api_key" => "test_key"}}
        }))

        FileUtils.mkdir_p(File.dirname(state_path))
        File.write(state_path, YAML.dump({
          "current_account" => "test",
          "accounts" => {"test" => {"workspace_id" => "ws-789"}}
        }))
      end

      it "shows workspace from account state" do
        result = run_cli("workspaces", "current")

        expect(result[:exit_code]).to eq(0)
        expect(result[:stdout]).to include("Current workspace: ws-789")
      end
    end
  end
end
