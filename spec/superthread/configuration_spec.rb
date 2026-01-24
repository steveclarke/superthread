# frozen_string_literal: true

require "tmpdir"

RSpec.describe Superthread::Configuration do
  subject(:config) { described_class.new }

  let(:config_dir) { Dir.mktmpdir }
  let(:state_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(config_dir, "superthread", "config.yaml") }
  let(:state_path) { File.join(state_dir, "superthread", "context.yaml") }

  around do |example|
    original_config = ENV["XDG_CONFIG_HOME"]
    original_state = ENV["XDG_STATE_HOME"]
    original_api_key = ENV["SUPERTHREAD_API_KEY"]
    original_workspace = ENV["SUPERTHREAD_WORKSPACE_ID"]
    original_account = ENV["SUPERTHREAD_ACCOUNT"]

    ENV["XDG_CONFIG_HOME"] = config_dir
    ENV["XDG_STATE_HOME"] = state_dir
    ENV.delete("SUPERTHREAD_API_KEY")
    ENV.delete("SUPERTHREAD_WORKSPACE_ID")
    ENV.delete("SUPERTHREAD_ACCOUNT")

    example.run

    ENV["XDG_CONFIG_HOME"] = original_config
    ENV["XDG_STATE_HOME"] = original_state
    ENV["SUPERTHREAD_API_KEY"] = original_api_key if original_api_key
    ENV["SUPERTHREAD_WORKSPACE_ID"] = original_workspace if original_workspace
    ENV["SUPERTHREAD_ACCOUNT"] = original_account if original_account
    FileUtils.rm_rf(config_dir)
    FileUtils.rm_rf(state_dir)
  end

  describe "#initialize" do
    it "sets default base_url" do
      expect(config.base_url).to eq("https://api.superthread.com/v1")
    end

    it "sets default format to table" do
      expect(config.format).to eq("table")
    end

    it "initializes with empty accounts" do
      expect(config.accounts).to eq({})
    end
  end

  describe "#config_path" do
    it "returns XDG-compliant path" do
      expect(config.config_path).to end_with("superthread/config.yaml")
    end

    it "uses XDG_CONFIG_HOME" do
      expect(config.config_path).to eq(File.join(config_dir, "superthread/config.yaml"))
    end
  end

  describe "#state_path" do
    it "returns XDG-compliant path" do
      expect(config.state_path).to end_with("superthread/context.yaml")
    end

    it "uses XDG_STATE_HOME" do
      expect(config.state_path).to eq(File.join(state_dir, "superthread/context.yaml"))
    end
  end

  describe "#add_account" do
    it "adds account to config" do
      config.add_account("personal", api_key: "stp_xxx")

      expect(config.accounts[:personal]).to eq({api_key: "stp_xxx"})
    end

    it "persists to config file" do
      config.add_account("personal", api_key: "stp_xxx")

      saved = YAML.safe_load_file(config_path)
      expect(saved["accounts"]["personal"]["api_key"]).to eq("stp_xxx")
    end

    it "allows multiple accounts" do
      config.add_account("personal", api_key: "stp_xxx")
      config.add_account("work", api_key: "stp_yyy")

      expect(config.accounts.keys).to contain_exactly(:personal, :work)
    end
  end

  describe "#remove_account" do
    before do
      config.add_account("personal", api_key: "stp_xxx")
      config.add_account("work", api_key: "stp_yyy")
      config.save_account_state("personal", workspace_id: "ws_123")
      config.set_current_account("personal")
    end

    it "removes account from config" do
      config.remove_account("personal")

      expect(config.accounts).not_to have_key(:personal)
    end

    it "removes account state" do
      config.remove_account("personal")

      expect(config.account_state("personal")).to eq({})
    end

    it "clears current_account if removing active account" do
      config.remove_account("personal")

      expect(config.current_account).to be_nil
    end
  end

  describe "#current_account" do
    before do
      config.add_account("personal", api_key: "stp_xxx")
    end

    it "returns nil when no account is set" do
      expect(config.current_account).to be_nil
    end

    it "returns the current account after setting" do
      config.set_current_account("personal")

      expect(config.current_account).to eq("personal")
    end

    context "with SUPERTHREAD_ACCOUNT env var" do
      before { ENV["SUPERTHREAD_ACCOUNT"] = "work" }

      it "overrides state file" do
        config.set_current_account("personal")

        new_config = described_class.new
        expect(new_config.current_account).to eq("work")
      end
    end
  end

  describe "#current_account=" do
    before do
      config.add_account("personal", api_key: "stp_xxx")
    end

    it "switches to the account" do
      config.current_account = "personal"

      expect(config.current_account).to eq("personal")
    end

    it "raises error for unknown account" do
      expect { config.current_account = "unknown" }
        .to raise_error(Superthread::ConfigurationError, /not found/)
    end

    it "persists to state file" do
      config.current_account = "personal"

      saved = YAML.safe_load_file(state_path)
      expect(saved["current_account"]).to eq("personal")
    end
  end

  describe "#save_account_state" do
    before do
      config.add_account("personal", api_key: "stp_xxx")
    end

    it "saves workspace state for account" do
      config.save_account_state("personal", workspace_id: "ws_123", workspace_name: "My Team")

      expect(config.account_state("personal")).to eq({
        workspace_id: "ws_123",
        workspace_name: "My Team"
      })
    end

    it "persists to state file" do
      config.save_account_state("personal", workspace_id: "ws_123")

      saved = YAML.safe_load_file(state_path)
      expect(saved["accounts"]["personal"]["workspace_id"]).to eq("ws_123")
    end
  end

  describe "#api_key" do
    before do
      config.add_account("personal", api_key: "stp_personal")
      config.add_account("work", api_key: "stp_work")
    end

    it "returns nil when no current account" do
      expect(config.api_key).to be_nil
    end

    it "returns current account's api_key" do
      config.set_current_account("personal")

      expect(config.api_key).to eq("stp_personal")
    end

    it "changes when switching accounts" do
      config.set_current_account("personal")
      expect(config.api_key).to eq("stp_personal")

      config.current_account = "work"
      expect(config.api_key).to eq("stp_work")
    end

    context "with SUPERTHREAD_API_KEY env var" do
      before { ENV["SUPERTHREAD_API_KEY"] = "stp_from_env" }

      it "overrides account api_key" do
        config.set_current_account("personal")

        new_config = described_class.new
        expect(new_config.api_key).to eq("stp_from_env")
      end
    end
  end

  describe "#workspace" do
    before do
      config.add_account("personal", api_key: "stp_xxx")
      config.save_account_state("personal", workspace_id: "ws_personal")
      config.set_current_account("personal")
    end

    it "returns current account's workspace" do
      expect(config.workspace).to eq("ws_personal")
    end

    context "with SUPERTHREAD_WORKSPACE_ID env var" do
      before { ENV["SUPERTHREAD_WORKSPACE_ID"] = "ws_from_env" }

      it "overrides account workspace" do
        new_config = described_class.new
        expect(new_config.workspace).to eq("ws_from_env")
      end
    end
  end

  describe "#validate!" do
    it "raises error when no account configured" do
      expect { config.validate! }
        .to raise_error(Superthread::ConfigurationError, /No account configured/)
    end

    it "raises error when account has no api_key" do
      config.add_account("personal", api_key: "")
      config.set_current_account("personal")

      expect { config.validate! }
        .to raise_error(Superthread::ConfigurationError, /API key not found/)
    end

    it "passes when account is properly configured" do
      config.add_account("personal", api_key: "stp_xxx")
      config.set_current_account("personal")

      expect { config.validate! }.not_to raise_error
    end
  end

  describe "#accounts?" do
    it "returns false when no accounts" do
      expect(config.accounts?).to be false
    end

    it "returns true when accounts exist" do
      config.add_account("personal", api_key: "stp_xxx")

      expect(config.accounts?).to be true
    end
  end

  describe "loading from files" do
    it "loads accounts from config file" do
      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, YAML.dump({
        "accounts" => {
          "personal" => {"api_key" => "stp_xxx"},
          "work" => {"api_key" => "stp_yyy"}
        }
      }))

      new_config = described_class.new
      expect(new_config.accounts.keys).to contain_exactly(:personal, :work)
    end

    it "loads current_account from state file" do
      FileUtils.mkdir_p(File.dirname(config_path))
      FileUtils.mkdir_p(File.dirname(state_path))
      File.write(config_path, YAML.dump({
        "accounts" => {"personal" => {"api_key" => "stp_xxx"}}
      }))
      File.write(state_path, YAML.dump({
        "current_account" => "personal",
        "accounts" => {"personal" => {"workspace_id" => "ws_123"}}
      }))

      new_config = described_class.new
      expect(new_config.current_account).to eq("personal")
      expect(new_config.workspace).to eq("ws_123")
    end
  end

  describe "base_url env override" do
    before { ENV["SUPERTHREAD_API_BASE_URL"] = "https://custom.api.com" }
    after { ENV.delete("SUPERTHREAD_API_BASE_URL") }

    it "uses the env var value" do
      new_config = described_class.new
      expect(new_config.base_url).to eq("https://custom.api.com")
    end
  end
end
