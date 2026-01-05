# frozen_string_literal: true

module Superthread
  module Resources
    class Base
      def initialize(client)
        @client = client
      end

      private

      # HTTP verb helpers
      def get(path, params: nil)
        @client.request(method: :get, path: path, params: params)
      end

      def post(path, body: nil)
        @client.request(method: :post, path: path, body: body)
      end

      def patch(path, body: nil)
        @client.request(method: :patch, path: path, body: body)
      end

      def delete(path)
        @client.request(method: :delete, path: path)
      end

      # Validates and sanitizes an ID to prevent path traversal attacks.
      # Only allows alphanumeric characters, hyphens, and underscores.
      #
      # @param name [String] Descriptive name for error messages (e.g., "workspace_id")
      # @param value [String] The ID value to validate
      # @return [String] The sanitized ID
      # @raise [Superthread::PathValidationError] If the value is invalid
      #
      # @example
      #   safe_id("workspace_id", "ws-123_abc") # => "ws-123_abc"
      #   safe_id("card_id", "../evil")         # raises PathValidationError
      def safe_id(name, value)
        if value.nil? || value.to_s.empty?
          raise Superthread::PathValidationError, "#{name} must be a non-empty string"
        end

        cleaned = value.to_s.strip.gsub(/[^a-zA-Z0-9_-]/, "")

        if cleaned.empty?
          raise Superthread::PathValidationError,
            "#{name} must contain only letters, numbers, hyphen, or underscore"
        end

        cleaned
      end

      # Builds a params hash, filtering out nil values.
      # Equivalent to TypeScript's buildParams helper.
      #
      # @param args [Hash] Key-value pairs for parameters
      # @return [Hash] Hash with nil values removed
      def build_params(**args)
        args.compact
      end

      # Build API path with workspace ID
      # Uses modern UI terminology (workspace_id) internally, translates to API (team_id)
      def workspace_path(workspace_id, path = "")
        ws = safe_id("workspace_id", workspace_id)
        "/#{ws}#{path}"
      end
    end
  end
end
