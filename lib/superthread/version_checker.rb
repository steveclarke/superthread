# frozen_string_literal: true

require "faraday"
require "json"
require "fileutils"

module Superthread
  # Checks for newer versions of the Superthread CLI.
  #
  # Uses the GitHub Releases API to find the latest version and caches
  # the result to avoid repeated network requests. Designed to never
  # interrupt or slow down normal CLI usage.
  #
  # @example Check for updates
  #   Superthread::VersionChecker.check_if_stale!
  #   if (notice = Superthread::VersionChecker.update_notice)
  #     $stderr.puts notice
  #   end
  #
  # @example Force check (bypass cache TTL)
  #   latest = Superthread::VersionChecker.check!
  module VersionChecker
    # GitHub API endpoint for the latest release.
    RELEASES_URL = "https://api.github.com/repos/steveclarke/superthread/releases/latest"

    # How long to cache the version check result (24 hours).
    CACHE_TTL = 86_400

    # HTTP connect timeout in seconds.
    CONNECT_TIMEOUT = 3

    # HTTP read timeout in seconds.
    READ_TIMEOUT = 5

    module_function

    # Returns a formatted update notice if a newer version is available.
    #
    # Reads from cache only — does not make network requests.
    # Returns nil if no update is available, cache is missing, or
    # update checks are disabled.
    #
    # @return [String, nil] update message or nil
    def update_notice
      return nil if disabled?

      cached = read_cache
      return nil unless cached

      latest = cached[:latest_version]
      return nil unless latest
      return nil unless newer?(latest)

      current = Superthread::VERSION
      "\n" \
        "  Update available: #{current} \u2192 #{latest}\n" \
        "  Run: brew upgrade superthread\n"
    end

    # Fetches the latest version from GitHub and updates the cache.
    #
    # Always makes a network request regardless of cache freshness.
    # Returns nil silently on any error (network, parse, etc.).
    #
    # @return [String, nil] the latest version string, or nil on failure
    def check!
      return nil if disabled?

      version = fetch_latest_version
      write_cache(version) if version
      version
    rescue
      nil
    end

    # Fetches the latest version only if the cache is stale.
    #
    # If the cache is fresh (less than {CACHE_TTL} old), does nothing.
    # This is the method to call on every CLI invocation — it's
    # effectively free when the cache is warm.
    #
    # @return [String, nil] the latest version string, or nil
    def check_if_stale!
      return nil if disabled?

      cached = read_cache
      if cached && (Time.now.to_i - cached[:checked_at].to_i) < CACHE_TTL
        return cached[:latest_version]
      end

      check!
    rescue
      nil
    end

    # Whether version checking is disabled via environment variable.
    #
    # @return [Boolean] true if SUPERTHREAD_NO_UPDATE_CHECK is set
    def disabled?
      ENV.key?("SUPERTHREAD_NO_UPDATE_CHECK")
    end

    # Compares a version string against the current version.
    #
    # @param version [String] the version to compare
    # @return [Boolean] true if the given version is newer
    def newer?(version)
      Gem::Version.new(version) > Gem::Version.new(Superthread::VERSION)
    rescue ArgumentError
      false
    end

    # Returns the path to the version check cache file.
    #
    # @return [String] absolute path to version_check.json
    def cache_path
      File.join(
        ENV.fetch("XDG_STATE_HOME", File.expand_path("~/.local/state")),
        "superthread",
        "version_check.json"
      )
    end

    # Reads the cached version check result.
    #
    # @return [Hash{Symbol => Object}, nil] cached data or nil
    def read_cache
      return nil unless File.exist?(cache_path)

      data = JSON.parse(File.read(cache_path), symbolize_names: true)
      data if data.is_a?(Hash)
    rescue JSON::ParserError, Errno::ENOENT
      nil
    end

    # Writes a version check result to the cache file.
    #
    # @param version [String] the latest version string
    # @return [void]
    def write_cache(version)
      FileUtils.mkdir_p(File.dirname(cache_path))
      File.write(cache_path, JSON.generate(
        latest_version: version,
        checked_at: Time.now.to_i
      ))
    rescue Errno::EACCES, Errno::ENOSPC
      nil
    end

    # Fetches the latest version tag from GitHub Releases API.
    #
    # @return [String, nil] version string (without leading "v"), or nil
    def fetch_latest_version
      conn = Faraday.new(url: RELEASES_URL) do |f|
        f.headers["Accept"] = "application/vnd.github+json"
        f.options.timeout = READ_TIMEOUT
        f.options.open_timeout = CONNECT_TIMEOUT
        f.adapter Faraday.default_adapter
      end

      response = conn.get
      return nil unless response.status == 200

      data = JSON.parse(response.body, symbolize_names: true)
      tag = data[:tag_name]
      return nil unless tag

      # Strip leading "v" (e.g., "v0.5.7" -> "0.5.7")
      tag.sub(/\Av/, "")
    rescue Faraday::Error, JSON::ParserError
      nil
    end
  end
end
