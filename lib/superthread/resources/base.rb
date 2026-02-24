# frozen_string_literal: true

module Superthread
  # API resource classes for interacting with Superthread endpoints.
  module Resources
    # Base class for all API resources.
    #
    # Provides HTTP helpers, ID validation, and response handling shared
    # by all resource classes. Subclasses should use the protected HTTP
    # methods to interact with the Superthread API.
    class Base
      # Initializes a new resource instance.
      #
      # @param client [Superthread::Client] the API client for making requests
      def initialize(client)
        @client = client
      end

      private

      # Performs a GET request and returns raw response data.
      #
      # @param path [String] the API endpoint path
      # @param params [Hash{Symbol => Object}, nil] optional query parameters
      # @return [Hash{Symbol => Object}] the parsed response body
      def http_get(path, params: nil)
        @client.request(method: :get, path: path, params: params)
      end

      # Performs a POST request and returns raw response data.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash{Symbol => Object}, nil] optional request body
      # @return [Hash{Symbol => Object}] the parsed response body
      def http_post(path, body: nil)
        @client.request(method: :post, path: path, body: body)
      end

      # Performs a PATCH request and returns raw response data.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash{Symbol => Object}, nil] optional request body
      # @return [Hash{Symbol => Object}] the parsed response body
      def http_patch(path, body: nil)
        @client.request(method: :patch, path: path, body: body)
      end

      # Performs a DELETE request and returns raw response data.
      #
      # @param path [String] the API endpoint path
      # @return [Hash{Symbol => Object}] the parsed response body
      def http_delete(path)
        @client.request(method: :delete, path: path)
      end

      # Performs a GET request and returns a typed object.
      #
      # @param path [String] the API endpoint path
      # @param params [Hash{Symbol => Object}, nil] optional query parameters
      # @param object_class [Class, nil] the model class to instantiate
      # @param unwrap_key [Symbol, nil] key to extract from response before wrapping
      # @return [Superthread::Object] the response wrapped in an object
      def get_object(path, params: nil, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :get, path: path, params: params,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      # Performs a POST request and returns a typed object.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash{Symbol => Object}, nil] optional request body
      # @param object_class [Class, nil] the model class to instantiate
      # @param unwrap_key [Symbol, nil] key to extract from response before wrapping
      # @return [Superthread::Object] the response wrapped in an object
      def post_object(path, body: nil, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :post, path: path, body: body,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      # Performs a PATCH request and returns a typed object.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash{Symbol => Object}, nil] optional request body
      # @param object_class [Class, nil] the model class to instantiate
      # @param unwrap_key [Symbol, nil] key to extract from response before wrapping
      # @return [Superthread::Object] the response wrapped in an object
      def patch_object(path, body: nil, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :patch, path: path, body: body,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      # Performs a DELETE request and returns a typed object.
      #
      # @param path [String] the API endpoint path
      # @param object_class [Class, nil] the model class to instantiate
      # @param unwrap_key [Symbol, nil] key to extract from response before wrapping
      # @return [Superthread::Object] the response wrapped in an object
      def delete_object(path, object_class: nil, unwrap_key: nil)
        @client.request_object(
          method: :delete, path: path,
          object_class: object_class, unwrap_key: unwrap_key
        )
      end

      # Performs a GET request and returns a collection of objects.
      #
      # @param path [String] the API endpoint path
      # @param params [Hash{Symbol => Object}, nil] optional query parameters
      # @param item_class [Class, nil] the model class for collection items
      # @param items_key [Symbol, nil] key containing the array in response
      # @return [Superthread::Objects::Collection] the collection of items
      def get_collection(path, params: nil, item_class: nil, items_key: nil)
        @client.request_collection(
          method: :get, path: path, params: params,
          item_class: item_class, items_key: items_key
        )
      end

      # Performs a POST request and returns a collection of objects.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash{Symbol => Object}, nil] optional request body
      # @param item_class [Class, nil] the model class for collection items
      # @param items_key [Symbol, nil] key containing the array in response
      # @return [Superthread::Objects::Collection] the collection of items
      def post_collection(path, body: nil, item_class: nil, items_key: nil)
        @client.request_collection(
          method: :post, path: path, body: body,
          item_class: item_class, items_key: items_key
        )
      end

      # Validates and sanitizes an ID to prevent path traversal attacks.
      #
      # Only allows alphanumeric characters, hyphens, and underscores.
      #
      # @param name [String] descriptive name for error messages (e.g., "workspace_id")
      # @param value [String] the ID value to validate
      # @return [String] the sanitized ID
      # @raise [Superthread::PathValidationError] if the value is nil, empty, or contains invalid characters
      # @example
      #   safe_id("workspace_id", "ws-123_abc") # => "ws-123_abc"
      #   safe_id("card_id", "../evil")         # raises PathValidationError
      def safe_id(name, value)
        raise Superthread::PathValidationError, "#{name} must be a non-empty string" if value.nil? || value.to_s.empty?

        cleaned = value.to_s.strip.gsub(/[^a-zA-Z0-9_-]/, "")

        if cleaned.empty?
          raise Superthread::PathValidationError,
            "#{name} must contain only letters, numbers, hyphen, or underscore"
        end

        cleaned
      end

      # Filters nil values from a params hash.
      #
      # Accepts arbitrary keyword arguments and returns only non-nil values.
      # Used internally to clean up API request parameters.
      #
      # @param args [Hash{Symbol => Object}] arbitrary key-value pairs to filter
      # @option args [Object] :any any key-value pair (nil values will be removed)
      # @return [Hash{Symbol => Object}] hash with nil values removed
      def compact_params(**args)
        args.compact
      end

      # Formats {{@mentions}} in content to HTML user-mention tags.
      #
      # @param workspace_id [String] the workspace identifier for member lookup
      # @param content [String, nil] text that may contain {{@Name}} patterns
      # @return [String, nil] content with mentions converted to HTML tags
      def format_mentions(workspace_id, content)
        return content if content.nil?

        MentionFormatter.new(@client, workspace_id).format(content)
      end

      # Builds an API path prefixed with the workspace ID.
      #
      # @param workspace_id [String] the workspace identifier
      # @param path [String] additional path segments to append
      # @return [String] the full API path (e.g., "/ws-123/cards")
      def workspace_path(workspace_id, path = "")
        ws = safe_id("workspace_id", workspace_id)
        "/#{ws}#{path}"
      end

      # Returns a success response object for delete operations.
      #
      # @return [Superthread::Object] a response object with success: true
      def success_response
        Superthread::Object.new(success: true)
      end
    end
  end
end
