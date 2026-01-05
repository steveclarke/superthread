# frozen_string_literal: true

RSpec.describe Superthread::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default base_url" do
      expect(config.base_url).to eq("https://api.superthread.com/v1")
    end

    it "sets default format to json" do
      expect(config.format).to eq("json")
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
end
