# frozen_string_literal: true

module Superthread
  module Resources
    # Base class for all API resources.
    # Provides HTTP helpers, ID validation, and response handling.
    class Base
      def initialize(client)
        @client = client
      end

      private

      # HTTP verb helpers that return raw hashes.
      # Use these when you need the raw response data.

      def http_get(path, params: nil)
        @client.request(method: :get, path: path, params: params)
      end

      def http_post(path, body: nil)
        @client.request(method: :post, path: path, body: body)
      end

      def http_patch(path, body: nil)
        @client.request(method: :patch, path: path, body: body)
      end

      def http_delete(path)
        @client.request(method: :delete, path: path)
      end

      # HTTP verb helpers that return Superthread::Object instances.
      # These are the preferred methods for most API calls.

      def get_object(path, params: nil, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :get, path: path, params: params,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      def post_object(path, body: nil, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :post, path: path, body: body,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      def patch_object(path, body: nil, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :patch, path: path, body: body,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      def delete_object(path, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :delete, path: path,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      # HTTP verb helpers that return Collections.

      def get_collection(path, params: nil, item_class: nil, items_key: nil)
        @client.request_collection(
          method: :get, path: path, params: params,
          item_class: item_class, items_key: items_key
        )
      end

      def post_collection(path, body: nil, item_class: nil, items_key: nil)
        @client.request_collection(
          method: :post, path: path, body: body,
          item_class: item_class, items_key: items_key
        )
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
        raise Superthread::PathValidationError, "#{name} must be a non-empty string" if value.nil? || value.to_s.empty?

        cleaned = value.to_s.strip.gsub(/[^a-zA-Z0-9_-]/, '')

        if cleaned.empty?
          raise Superthread::PathValidationError,
                "#{name} must contain only letters, numbers, hyphen, or underscore"
        end

        cleaned
      end

      # Filters nil values from a params hash.
      #
      # @param args [Hash] Key-value pairs for parameters
      # @return [Hash] Hash with nil values removed
      def compact_params(**args)
        args.compact
      end

      # Build API path with workspace ID.
      #
      # @param workspace_id [String] The workspace ID
      # @param path [String] Additional path to append
      # @return [String] Full API path
      def workspace_path(workspace_id, path = '')
        ws = safe_id('workspace_id', workspace_id)
        "/#{ws}#{path}"
      end

      # Returns a success response object for delete operations.
      #
      # @return [Superthread::Object] Success response
      def success_response
        Superthread::Object.new(success: true)
      end
    end
  end
end
