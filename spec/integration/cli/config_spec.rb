# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st config", :cli do
  # Note: The :cli tag automatically isolates tests from user's real config
  # by using temp directories for XDG_CONFIG_HOME and XDG_STATE_HOME

  describe "config path" do
    it "shows the config file path" do
      result = run_cli("config", "path")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("config")
      expect(result[:stdout]).to include("superthread")
    end
  end

  describe "config init" do
    it "creates a config file" do
      result = run_cli("config", "init")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Created config file")
    end

    it "warns if config already exists" do
      # Create config first
      run_cli("config", "init")

      # Try to create again
      result = run_cli("config", "init")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("already exists")
    end
  end

  describe "config show" do
    it "shows current configuration" do
      # First init config
      run_cli("config", "init")

      result = run_cli("config", "show")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Config file:")
      expect(result[:stdout]).to include("format:")
    end

    it "shows accounts when configured" do
      # This would require setting up an account first
      # For now just verify the command runs
      result = run_cli("config", "show")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Accounts:")
    end
  end

  describe "config set KEY VALUE" do
    it "sets the output format" do
      result = run_cli("config", "set", "format", "json")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Set format = json")
    end

    it "rejects invalid format values" do
      result = run_cli("config", "set", "format", "invalid")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include("Invalid format")
    end

    it "rejects unknown config keys" do
      result = run_cli("config", "set", "unknown_key", "value")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include("Unknown config key")
    end

    it "rejects api_key (managed per-account now)" do
      result = run_cli("config", "set", "api_key", "stp_test123")

      expect(result[:exit_code]).to eq(1)
      expect(result[:stderr]).to include("Unknown config key")
    end

    it "persists configuration changes" do
      run_cli("config", "set", "format", "json")

      result = run_cli("config", "show")

      expect(result[:stdout]).to include("format: json")
    end
  end
end
