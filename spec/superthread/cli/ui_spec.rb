# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Superthread::Cli::Ui do
  include CliHelpers

  around do |example|
    original_plain = ENV["SUPERTHREAD_PLAIN"]
    original_term = ENV["TERM_PROGRAM"]
    example.run
  ensure
    if original_plain
      ENV["SUPERTHREAD_PLAIN"] = original_plain
    else
      ENV.delete("SUPERTHREAD_PLAIN")
    end
    if original_term
      ENV["TERM_PROGRAM"] = original_term
    else
      ENV.delete("TERM_PROGRAM")
    end
    described_class.reset_prompt!
  end

  describe ".plain_mode?" do
    it "returns true when SUPERTHREAD_PLAIN is set" do
      ENV["SUPERTHREAD_PLAIN"] = "1"
      ENV.delete("TERM_PROGRAM")

      expect(described_class.plain_mode?).to be true
    end

    it "returns true when TERM_PROGRAM is Apple_Terminal" do
      ENV.delete("SUPERTHREAD_PLAIN")
      ENV["TERM_PROGRAM"] = "Apple_Terminal"

      expect(described_class.plain_mode?).to be true
    end

    it "returns false for other terminals" do
      ENV.delete("SUPERTHREAD_PLAIN")
      ENV["TERM_PROGRAM"] = "iTerm2"

      expect(described_class.plain_mode?).to be false
    end

    it "returns false when no env vars are set" do
      ENV.delete("SUPERTHREAD_PLAIN")
      ENV.delete("TERM_PROGRAM")

      expect(described_class.plain_mode?).to be false
    end
  end

  describe ".prompt" do
    it "returns PlainPrompt in plain mode" do
      ENV["SUPERTHREAD_PLAIN"] = "1"
      described_class.reset_prompt!

      expect(described_class.prompt).to eq(Superthread::Cli::Ui::PlainPrompt)
    end

    it "returns GumPrompt for capable terminals" do
      ENV.delete("SUPERTHREAD_PLAIN")
      ENV["TERM_PROGRAM"] = "iTerm2"
      described_class.reset_prompt!

      expect(described_class.prompt).to eq(Superthread::Cli::Ui::GumPrompt)
    end
  end

  context "with PlainPrompt" do
    before do
      ENV["SUPERTHREAD_PLAIN"] = "1"
      described_class.reset_prompt!
    end

    describe ".input" do
      it "reads from stdin" do
        result = nil
        with_stdin("my input\n") do
          capture(:stdout) { result = described_class.input("Name:") }
        end

        expect(result).to eq("my input")
      end

      it "prints the prompt" do
        output = with_stdin("hello\n") do
          capture(:stdout) { described_class.input("Name:") }
        end

        expect(output).to include("Name:")
      end
    end

    describe ".password" do
      it "reads without echoing" do
        result = nil
        with_stdin("secret\n") do
          allow($stdin).to receive(:noecho).and_yield($stdin)
          capture(:stdout) { result = described_class.password("API key:") }
        end

        expect(result).to eq("secret")
      end
    end

    describe ".confirm" do
      it "returns true for 'y'" do
        result = nil
        with_stdin("y\n") do
          capture(:stdout) { result = described_class.confirm("Delete?", default: false) }
        end

        expect(result).to be true
      end

      it "returns false for 'n'" do
        result = nil
        with_stdin("n\n") do
          capture(:stdout) { result = described_class.confirm("Delete?", default: true) }
        end

        expect(result).to be false
      end

      it "returns default when input is empty" do
        result = nil
        with_stdin("\n") do
          capture(:stdout) { result = described_class.confirm("Continue?", default: true) }
        end

        expect(result).to be true
      end

      it "shows Y/n hint when default is true" do
        output = with_stdin("\n") do
          capture(:stdout) { described_class.confirm("Continue?", default: true) }
        end

        expect(output).to include("(Y/n)")
      end

      it "shows y/N hint when default is false" do
        output = with_stdin("\n") do
          capture(:stdout) { described_class.confirm("Delete?", default: false) }
        end

        expect(output).to include("(y/N)")
      end
    end

    describe ".choose" do
      it "shows numbered list and returns selected item" do
        result = nil
        output = with_stdin("2\n") do
          capture(:stdout) { result = described_class.choose(["alpha", "beta", "gamma"]) }
        end

        expect(output).to include("1. alpha")
        expect(output).to include("2. beta")
        expect(output).to include("3. gamma")
        expect(result).to eq("beta")
      end

      it "shows header when provided" do
        output = with_stdin("1\n") do
          capture(:stdout) { described_class.choose(["a"], header: "Pick one:") }
        end

        expect(output).to include("Pick one:")
      end

      it "defaults to first item for out-of-range input" do
        result = nil
        with_stdin("99\n") do
          capture(:stdout) { result = described_class.choose(["alpha", "beta"]) }
        end

        expect(result).to eq("alpha")
      end

      it "defaults to first item for empty input" do
        result = nil
        with_stdin("\n") do
          capture(:stdout) { result = described_class.choose(["alpha", "beta"]) }
        end

        expect(result).to eq("alpha")
      end
    end

    describe ".filter" do
      it "falls back to numbered list" do
        result = nil
        output = with_stdin("1\n") do
          capture(:stdout) { result = described_class.filter(["x", "y"]) }
        end

        expect(output).to include("1. x")
        expect(result).to eq("x")
      end
    end

    describe ".spin" do
      it "prints title and yields block" do
        result = nil
        output = capture(:stdout) { result = described_class.spin("Loading") { 42 } }

        expect(output).to include("Loading...")
        expect(output).to include("done")
        expect(result).to eq(42)
      end
    end
  end

  private

  def with_stdin(input)
    original = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = original
  end
end
