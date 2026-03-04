# frozen_string_literal: true

require "spec_helper"

RSpec.describe "suth accounts add", :cli do
  before do
    # Gum.spin spawns a subprocess which conflicts with stdin redirection
    allow(Superthread::Cli::Ui).to receive(:spin).and_yield
    allow(Superthread::Cli::Ui).to receive(:muted) { |msg| puts msg }
  end

  let(:single_workspace_response) do
    {
      user: {
        id: "user-1",
        name: "Test User",
        email: "test@example.com",
        teams: [
          {id: "ws-123", team_name: "My Team", role: "admin"}
        ]
      }
    }
  end

  let(:multi_workspace_response) do
    {
      user: {
        id: "user-1",
        name: "Test User",
        email: "test@example.com",
        teams: [
          {id: "ws-123", team_name: "My Team", role: "admin"},
          {id: "ws-456", team_name: "Other Team", role: "member"}
        ]
      }
    }
  end

  describe "--with-token" do
    it "reads API key from stdin" do
      stub_api_get("users/me", response: single_workspace_response)
      original_stdin = $stdin
      $stdin = StringIO.new("stp_test_key\n")

      result = run_cli("accounts", "add", "myaccount", "--with-token")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("myaccount")
      expect(result[:stdout]).to include("configured")
    ensure
      $stdin = original_stdin
    end

    it "errors when stdin is empty" do
      original_stdin = $stdin
      $stdin = StringIO.new("")

      result = run_cli("accounts", "add", "myaccount", "--with-token")

      expect(result[:stdout]).to include("No API key provided")
      expect(result[:stdout]).to include("echo $SUPERTHREAD_API_KEY")
    ensure
      $stdin = original_stdin
    end

    it "auto-selects workspace when only one exists" do
      stub_api_get("users/me", response: single_workspace_response)
      original_stdin = $stdin
      $stdin = StringIO.new("stp_test_key\n")

      result = run_cli("accounts", "add", "myaccount", "--with-token")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("My Team")
    ensure
      $stdin = original_stdin
    end

    it "auto-selects first workspace when multiple exist" do
      stub_api_get("users/me", response: multi_workspace_response)
      original_stdin = $stdin
      $stdin = StringIO.new("stp_test_key\n")

      result = run_cli("accounts", "add", "myaccount", "--with-token")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("My Team")
      expect(result[:stdout]).to include("Multiple workspaces found")
    ensure
      $stdin = original_stdin
    end
  end

  describe "--workspace-name" do
    it "selects workspace by name" do
      stub_api_get("users/me", response: multi_workspace_response)
      original_stdin = $stdin
      $stdin = StringIO.new("stp_test_key\n")

      result = run_cli("accounts", "add", "myaccount", "--with-token", "--workspace-name", "Other Team")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Other Team")
    ensure
      $stdin = original_stdin
    end

    it "errors when workspace name not found" do
      stub_api_get("users/me", response: multi_workspace_response)
      original_stdin = $stdin
      $stdin = StringIO.new("stp_test_key\n")

      result = run_cli("accounts", "add", "myaccount", "--with-token", "--workspace-name", "Nonexistent")

      expect(result[:stdout]).to include("not found")
      expect(result[:stdout]).to include("My Team")
      expect(result[:stdout]).to include("Other Team")
    ensure
      $stdin = original_stdin
    end

    it "matches workspace name case-insensitively" do
      stub_api_get("users/me", response: multi_workspace_response)
      original_stdin = $stdin
      $stdin = StringIO.new("stp_test_key\n")

      result = run_cli("accounts", "add", "myaccount", "--with-token", "--workspace-name", "other team")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Other Team")
    ensure
      $stdin = original_stdin
    end
  end

  describe "duplicate account" do
    it "errors when account already exists" do
      stub_api_get("users/me", response: single_workspace_response)
      original_stdin = $stdin

      # Add first account
      $stdin = StringIO.new("stp_test_key\n")
      run_cli("accounts", "add", "myaccount", "--with-token")

      # Try to add again
      $stdin = StringIO.new("stp_test_key\n")
      result = run_cli("accounts", "add", "myaccount", "--with-token")

      expect(result[:stdout]).to include("already exists")
    ensure
      $stdin = original_stdin
    end
  end
end
