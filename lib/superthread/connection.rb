# frozen_string_literal: true

require "faraday"
require "json"

module Superthread
  # Low-level HTTP connection wrapper using Faraday.
  #
  # Handles the actual HTTP communication with the Superthread API,
  # including authentication headers, timeouts, and JSON encoding.
  #
  # @api private
  class Connection
    # Creates a new connection with the given configuration.
    #
    # @param config [Superthread::Configuration] configuration with API credentials
    def initialize(config)
      @config = config
      @connection = build_connection
    end

    # Performs an HTTP request to the API.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
    # @param path [String] API endpoint path (leading slash is stripped)
    # @param params [Hash{Symbol => Object}, nil] query parameters
    # @param body [Hash{Symbol => Object}, nil] request body (will be JSON-encoded)
    # @return [Faraday::Response] raw HTTP response
    def request(method:, path:, params: nil, body: nil)
      # Remove leading slash - Faraday treats /path as absolute from host root,
      # but we want it relative to the base URL (which includes /v1)
      relative_path = path.sub(%r{^/}, "")

      @connection.send(method) do |req|
        req.url(relative_path)
        req.params = params if params
        req.body = body.to_json if body
      end
    end

    private

    # Builds a configured Faraday connection for API requests.
    #
    # @return [Faraday::Connection] connection with auth headers and timeouts
    def build_connection
      Faraday.new(url: @config.base_url) do |conn|
        conn.headers["Authorization"] = "Bearer #{@config.api_key}"
        conn.headers["Content-Type"] = "application/json"
        conn.headers["Accept"] = "application/json"
        conn.options.timeout = @config.timeout
        conn.options.open_timeout = @config.open_timeout
        conn.adapter Faraday.default_adapter
      end
    end
  end
end
