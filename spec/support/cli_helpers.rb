# frozen_string_literal: true

require "stringio"

module CliHelpers
  # Capture stdout/stderr from a block
  #
  # @param stream [Symbol] :stdout, :stderr, or :both
  # @yield Block to capture output from
  # @return [String, Array<String>] Captured output
  def capture(stream = :stdout)
    case stream
    when :stdout
      captured = StringIO.new
      original = $stdout
      $stdout = captured
      yield
      captured.string
    when :stderr
      captured = StringIO.new
      original = $stderr
      $stderr = captured
      yield
      captured.string
    when :both
      stdout = StringIO.new
      stderr = StringIO.new
      original_stdout = $stdout
      original_stderr = $stderr
      $stdout = stdout
      $stderr = stderr
      yield
      [stdout.string, stderr.string]
    end
  ensure
    $stdout = original_stdout || original if defined?(original_stdout) || defined?(original)
    $stderr = original_stderr if defined?(original_stderr)
  end

  # Run a CLI command and capture output
  #
  # @param args [Array<String>] Command arguments (e.g., ["users", "me"])
  # @param capture_stderr [Boolean] Also capture stderr
  # @return [Hash] Result with :stdout, :stderr, :exit_code
  def run_cli(*args, capture_stderr: false)
    stdout = StringIO.new
    stderr = StringIO.new
    original_stdout = $stdout
    original_stderr = $stderr
    exit_code = 0

    begin
      $stdout = stdout
      $stderr = stderr
      Superthread::Cli::Main.start(args.flatten)
    rescue SystemExit => e
      exit_code = e.status
    rescue Thor::Error => e
      stderr.puts e.message
      exit_code = 1
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end

    {
      stdout: stdout.string,
      stderr: stderr.string,
      exit_code: exit_code
    }
  end

  # Run CLI and return just stdout (convenience method)
  #
  # @param args [Array<String>] Command arguments
  # @return [String] stdout output
  def cli_output(*args)
    run_cli(*args)[:stdout]
  end

  # Run CLI and parse JSON output
  #
  # @param args [Array<String>] Command arguments (--json flag added automatically)
  # @return [Hash, Array] Parsed JSON
  def cli_json(*args)
    args = args.flatten + ["--json"] unless args.include?("--json")
    output = cli_output(*args)
    JSON.parse(output)
  end

  # Assert CLI command succeeds
  #
  # @param args [Array<String>] Command arguments
  def expect_cli_success(*args)
    result = run_cli(*args)
    expect(result[:exit_code]).to eq(0),
      "Expected exit code 0, got #{result[:exit_code]}\nstderr: #{result[:stderr]}"
  end

  # Assert CLI command fails
  #
  # @param args [Array<String>] Command arguments
  # @param exit_code [Integer] Expected exit code (default: any non-zero)
  def expect_cli_failure(*args, exit_code: nil)
    result = run_cli(*args)
    if exit_code
      expect(result[:exit_code]).to eq(exit_code)
    else
      expect(result[:exit_code]).not_to eq(0)
    end
  end
end

RSpec.configure do |config|
  config.include CliHelpers, type: :cli
  config.include CliHelpers, :cli
end
