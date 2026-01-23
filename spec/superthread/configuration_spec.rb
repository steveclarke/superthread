# frozen_string_literal: true

require "tmpdir"

RSpec.describe Superthread::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default base_url" do
      expect(config.base_url).to eq("https://api.superthread.com/v1")
    end

    it "sets default format to table" do
      expect(config.format).to eq("table")
    end
  end

  describe "#api_key" do
    context "when SUPERTHREAD_API_KEY env var is set" do
      around do |example|
        original = ENV["SUPERTHREAD_API_KEY"]
        ENV["SUPERTHREAD_API_KEY"] = "test_key_from_env"
        example.run
        ENV["SUPERTHREAD_API_KEY"] = original
      end

      it "uses the env var value" do
        expect(config.api_key).to eq("test_key_from_env")
      end
    end
  end

  describe "#workspace" do
    context "when SUPERTHREAD_WORKSPACE_ID env var is set" do
      around do |example|
        original = ENV["SUPERTHREAD_WORKSPACE_ID"]
        ENV["SUPERTHREAD_WORKSPACE_ID"] = "ws_from_env"
        example.run
        ENV["SUPERTHREAD_WORKSPACE_ID"] = original
      end

      it "uses the env var value" do
        expect(config.workspace).to eq("ws_from_env")
      end
    end
  end

  describe "#base_url" do
    context "when SUPERTHREAD_API_BASE_URL env var is set" do
      around do |example|
        original = ENV["SUPERTHREAD_API_BASE_URL"]
        ENV["SUPERTHREAD_API_BASE_URL"] = "https://custom.api.com"
        example.run
        ENV["SUPERTHREAD_API_BASE_URL"] = original
      end

      it "uses the env var value" do
        expect(config.base_url).to eq("https://custom.api.com")
      end
    end
  end

  describe "#config_path" do
    it "returns XDG-compliant path" do
      expect(config.config_path).to end_with("superthread/config.yaml")
    end

    context "when XDG_CONFIG_HOME is set" do
      around do |example|
        original = ENV["XDG_CONFIG_HOME"]
        ENV["XDG_CONFIG_HOME"] = "/custom/config"
        example.run
        ENV["XDG_CONFIG_HOME"] = original
      end

      it "uses XDG_CONFIG_HOME" do
        expect(config.config_path).to eq("/custom/config/superthread/config.yaml")
      end
    end
  end

  describe "#state_path" do
    it "returns XDG-compliant path" do
      expect(config.state_path).to end_with("superthread/context.yaml")
    end

    context "when XDG_STATE_HOME is set" do
      around do |example|
        original = ENV["XDG_STATE_HOME"]
        ENV["XDG_STATE_HOME"] = "/custom/state"
        example.run
        ENV["XDG_STATE_HOME"] = original
      end

      it "uses XDG_STATE_HOME" do
        expect(config.state_path).to eq("/custom/state/superthread/context.yaml")
      end
    end
  end

  describe "#save_workspace" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:state_path) { File.join(temp_dir, "superthread", "context.yaml") }

    around do |example|
      original = ENV["XDG_STATE_HOME"]
      ENV["XDG_STATE_HOME"] = temp_dir
      example.run
      ENV["XDG_STATE_HOME"] = original
      FileUtils.rm_rf(temp_dir)
    end

    it "creates state directory and file" do
      config.save_workspace("ws_test123")
      expect(File.exist?(state_path)).to be true
    end

    it "saves workspace to state file" do
      config.save_workspace("ws_test123")
      saved_state = YAML.safe_load_file(state_path)
      expect(saved_state["workspace"]).to eq("ws_test123")
    end

    it "updates instance workspace" do
      config.save_workspace("ws_test123")
      expect(config.workspace).to eq("ws_test123")
    end

    it "preserves existing state values" do
      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(state_path, YAML.dump({"other_key" => "other_value"}))

      config.save_workspace("ws_new")

      saved_state = YAML.safe_load_file(state_path)
      expect(saved_state["other_key"]).to eq("other_value")
      expect(saved_state["workspace"]).to eq("ws_new")
    end
  end

  describe "#clear_workspace" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:state_path) { File.join(temp_dir, "superthread", "context.yaml") }

    around do |example|
      original = ENV["XDG_STATE_HOME"]
      ENV["XDG_STATE_HOME"] = temp_dir
      example.run
      ENV["XDG_STATE_HOME"] = original
      FileUtils.rm_rf(temp_dir)
    end

    it "clears instance workspace" do
      config.save_workspace("ws_test123")
      config.clear_workspace
      expect(config.workspace).to be_nil
    end

    it "removes state file if workspace was the only key" do
      config.save_workspace("ws_test123")
      config.clear_workspace
      expect(File.exist?(state_path)).to be false
    end

    it "preserves state file if other values exist" do
      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(state_path, YAML.dump({"workspace" => "ws_test", "other" => "value"}))

      # Reload config to pick up state
      new_config = described_class.new
      new_config.clear_workspace

      expect(File.exist?(state_path)).to be true
      saved_state = YAML.safe_load_file(state_path)
      expect(saved_state["other"]).to eq("value")
      expect(saved_state).not_to have_key("workspace")
    end
  end

  describe "workspace loading priority" do
    let(:config_dir) { Dir.mktmpdir }
    let(:state_dir) { Dir.mktmpdir }
    let(:config_path) { File.join(config_dir, "superthread", "config.yaml") }
    let(:state_path) { File.join(state_dir, "superthread", "context.yaml") }

    around do |example|
      original_config = ENV["XDG_CONFIG_HOME"]
      original_state = ENV["XDG_STATE_HOME"]
      original_workspace = ENV["SUPERTHREAD_WORKSPACE_ID"]
      ENV["XDG_CONFIG_HOME"] = config_dir
      ENV["XDG_STATE_HOME"] = state_dir
      ENV.delete("SUPERTHREAD_WORKSPACE_ID")
      example.run
      ENV["XDG_CONFIG_HOME"] = original_config
      ENV["XDG_STATE_HOME"] = original_state
      ENV["SUPERTHREAD_WORKSPACE_ID"] = original_workspace if original_workspace
      FileUtils.rm_rf(config_dir)
      FileUtils.rm_rf(state_dir)
    end

    it "loads workspace from state file" do
      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(state_path, YAML.dump("workspace" => "ws_from_state"))

      expect(config.workspace).to eq("ws_from_state")
    end

    it "env var overrides state file" do
      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(state_path, YAML.dump("workspace" => "ws_from_state"))
      ENV["SUPERTHREAD_WORKSPACE_ID"] = "ws_from_env"

      expect(config.workspace).to eq("ws_from_env")
    end

    context "legacy migration" do
      it "migrates workspace from config to state if state doesn't exist" do
        FileUtils.mkdir_p(File.dirname(config_path))
        File.write(config_path, YAML.dump("workspace" => "ws_legacy"))

        expect(config.workspace).to eq("ws_legacy")
      end

      it "prefers state file over legacy config workspace" do
        FileUtils.mkdir_p(File.dirname(config_path))
        FileUtils.mkdir_p(File.dirname(state_path))
        File.write(config_path, YAML.dump("workspace" => "ws_legacy"))
        File.write(state_path, YAML.dump("workspace" => "ws_current"))

        expect(config.workspace).to eq("ws_current")
      end
    end
  end
end
