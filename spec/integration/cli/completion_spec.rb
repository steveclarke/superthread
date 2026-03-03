# frozen_string_literal: true

require "spec_helper"

RSpec.describe "suth completion", :cli do
  describe "completion bash" do
    it "generates bash completion script" do
      result = run_cli("completion", "bash")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("# Bash completion for suth")
      expect(result[:stdout]).to include("_suth()")
      expect(result[:stdout]).to include("complete -F _suth suth")
    end

    it "includes all main commands" do
      result = run_cli("completion", "bash")

      %w[cards boards projects spaces pages notes comments search tags].each do |cmd|
        expect(result[:stdout]).to include(cmd)
      end
    end

    it "includes global options" do
      result = run_cli("completion", "bash")

      expect(result[:stdout]).to include("--verbose")
      expect(result[:stdout]).to include("--workspace")
      expect(result[:stdout]).to include("--json")
    end
  end

  describe "completion zsh" do
    it "generates zsh completion script" do
      result = run_cli("completion", "zsh")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("#compdef suth")
      expect(result[:stdout]).to include("# Zsh completion for suth")
      expect(result[:stdout]).to include("_suth()")
    end

    it "includes command descriptions" do
      result = run_cli("completion", "zsh")

      expect(result[:stdout]).to include("cards:Card management commands")
      expect(result[:stdout]).to include("boards:Board and list management commands")
    end

    it "includes subcommands with descriptions" do
      result = run_cli("completion", "zsh")

      expect(result[:stdout]).to include("list:List cards on a board")
      expect(result[:stdout]).to include("get:Get card details")
    end
  end

  describe "completion fish" do
    it "generates fish completion script" do
      result = run_cli("completion", "fish")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("# Fish completion for suth")
      expect(result[:stdout]).to include("complete -c suth")
    end

    it "uses fish built-in helper functions" do
      result = run_cli("completion", "fish")

      expect(result[:stdout]).to include("__fish_use_subcommand")
      expect(result[:stdout]).to include("__fish_seen_subcommand_from")
    end

    it "includes main commands with descriptions" do
      result = run_cli("completion", "fish")

      expect(result[:stdout]).to include("-a cards -d 'Card management commands'")
      expect(result[:stdout]).to include("-a boards -d 'Board and list management commands'")
    end

    it "includes subcommands" do
      result = run_cli("completion", "fish")

      expect(result[:stdout]).to include("__fish_seen_subcommand_from cards")
      expect(result[:stdout]).to include("-a list -d 'List cards on a board or sprint'")
    end
  end

  describe "completion help" do
    it "shows available shells" do
      result = run_cli("completion", "help")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("bash")
      expect(result[:stdout]).to include("zsh")
      expect(result[:stdout]).to include("fish")
    end
  end
end
