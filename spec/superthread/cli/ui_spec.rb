# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Superthread::Cli::Ui do
  around do |example|
    original_plain = ENV["SUPERTHREAD_PLAIN"]
    original_term = ENV["TERM_PROGRAM"]
    ENV["SUPERTHREAD_PLAIN"] = "1"
    ENV.delete("TERM_PROGRAM")
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

  describe ".input (plain mode)" do
    it "reads from stdin" do
      original_stdin = $stdin
      $stdin = StringIO.new("hello\n")

      result = capture(:stdout) { described_class.input("Name:") }

      expect(result).to include("Name:")
      expect(described_class.input("X: ")).to be_nil # stdin exhausted
    ensure
      $stdin = original_stdin
    end

    it "returns the entered text" do
      original_stdin = $stdin
      $stdin = StringIO.new("my input\n")

      result = nil
      capture(:stdout) { result = described_class.input("Prompt:") }

      expect(result).to eq("my input")
    ensure
      $stdin = original_stdin
    end
  end

  describe ".password (plain mode)" do
    it "reads without echoing" do
      original_stdin = $stdin
      $stdin = StringIO.new("secret\n")
      allow($stdin).to receive(:noecho).and_yield($stdin)

      result = nil
      capture(:stdout) { result = described_class.password("API key:") }

      expect(result).to eq("secret")
    ensure
      $stdin = original_stdin
    end
  end

  describe ".confirm (plain mode)" do
    it "returns true for 'y'" do
      original_stdin = $stdin
      $stdin = StringIO.new("y\n")

      result = nil
      capture(:stdout) { result = described_class.confirm("Delete?", default: false) }

      expect(result).to be true
    ensure
      $stdin = original_stdin
    end

    it "returns false for 'n'" do
      original_stdin = $stdin
      $stdin = StringIO.new("n\n")

      result = nil
      capture(:stdout) { result = described_class.confirm("Delete?", default: true) }

      expect(result).to be false
    ensure
      $stdin = original_stdin
    end

    it "returns default when input is empty" do
      original_stdin = $stdin
      $stdin = StringIO.new("\n")

      result = nil
      capture(:stdout) { result = described_class.confirm("Continue?", default: true) }

      expect(result).to be true
    ensure
      $stdin = original_stdin
    end

    it "shows Y/n hint when default is true" do
      original_stdin = $stdin
      $stdin = StringIO.new("\n")

      output = capture(:stdout) { described_class.confirm("Continue?", default: true) }

      expect(output).to include("(Y/n)")
    ensure
      $stdin = original_stdin
    end

    it "shows y/N hint when default is false" do
      original_stdin = $stdin
      $stdin = StringIO.new("\n")

      output = capture(:stdout) { described_class.confirm("Delete?", default: false) }

      expect(output).to include("(y/N)")
    ensure
      $stdin = original_stdin
    end
  end

  describe ".choose (plain mode)" do
    it "shows numbered list and returns selected item" do
      original_stdin = $stdin
      $stdin = StringIO.new("2\n")

      result = nil
      output = capture(:stdout) { result = described_class.choose(["alpha", "beta", "gamma"]) }

      expect(output).to include("1. alpha")
      expect(output).to include("2. beta")
      expect(output).to include("3. gamma")
      expect(result).to eq("beta")
    ensure
      $stdin = original_stdin
    end

    it "shows header when provided" do
      original_stdin = $stdin
      $stdin = StringIO.new("1\n")

      output = capture(:stdout) { described_class.choose(["a"], header: "Pick one:") }

      expect(output).to include("Pick one:")
    ensure
      $stdin = original_stdin
    end

    it "defaults to first item for invalid input" do
      original_stdin = $stdin
      $stdin = StringIO.new("99\n")

      result = nil
      capture(:stdout) { result = described_class.choose(["alpha", "beta"]) }

      expect(result).to eq("alpha")
    ensure
      $stdin = original_stdin
    end
  end

  describe ".filter (plain mode)" do
    it "falls back to numbered list" do
      original_stdin = $stdin
      $stdin = StringIO.new("1\n")

      result = nil
      output = capture(:stdout) { result = described_class.filter(["x", "y"]) }

      expect(output).to include("1. x")
      expect(result).to eq("x")
    ensure
      $stdin = original_stdin
    end
  end

  describe ".spin (plain mode)" do
    it "prints title and yields block" do
      result = nil
      output = capture(:stdout) { result = described_class.spin("Loading") { 42 } }

      expect(output).to include("Loading...")
      expect(output).to include("done")
      expect(result).to eq(42)
    end
  end

  private

  def capture(stream = :stdout)
    captured = StringIO.new
    original = $stdout
    $stdout = captured
    yield
    captured.string
  ensure
    $stdout = original
  end
end
