require "simplecov-review"

SimpleCov.start do
  enable_coverage :branch

  # Exclude non-application code
  add_filter "/spec/"
  add_filter "/vendor/"
  add_filter "/bin/"

  # Group files in the HTML report
  add_group "CLI", "lib/superthread/cli"
  add_group "Resources", "lib/superthread/resources"
  add_group "Models", "lib/superthread/models"
  add_group "Objects", "lib/superthread/objects"

  # Set minimum coverage (optional)
  # minimum_coverage line: 80

  # Output directory
  coverage_dir "coverage"

  # Use both HTML and Review formatters (Review is LLM-friendly)
  formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::ReviewFormatter
  ]
  formatter SimpleCov::Formatter::MultiFormatter.new(formatters)

  # Track all lib files even without tests
  track_files "lib/**/*.rb"
end
