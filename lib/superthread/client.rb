# frozen_string_literal: true

require "json"

module Superthread
  # HTTP client for the Superthread API.
  #
  # Provides access to all API resources through typed accessors.
  # Handles authentication, request signing, and response parsing.
  #
  # @example Creating a client
  #   client = Superthread::Client.new(api_key: "sk_...")
  #   cards = client.cards.list(workspace_id)
  #   card = client.cards.find(workspace_id, card_id)
  #
  # @example Using environment configuration
  #   # Uses SUPERTHREAD_API_KEY and config files
  #   client = Superthread::Client.new
  class Client
    # @return [Superthread::Resources::Users] users resource
    # @return [Superthread::Resources::Projects] projects resource
    # @return [Superthread::Resources::Spaces] spaces resource
    # @return [Superthread::Resources::Boards] boards resource
    # @return [Superthread::Resources::Cards] cards resource
    # @return [Superthread::Resources::Comments] comments resource
    # @return [Superthread::Resources::Pages] pages resource
    # @return [Superthread::Resources::Notes] notes resource
    # @return [Superthread::Resources::Sprints] sprints resource
    # @return [Superthread::Resources::Search] search resource
    # @return [Superthread::Resources::Tags] tags resource
    attr_reader :users, :projects, :spaces, :boards, :cards,
      :comments, :pages, :notes, :sprints, :search, :tags

    # @return [Faraday::Response, nil] the last HTTP response received
    attr_reader :last_response

    # Creates a new API client.
    #
    # @param api_key [String, nil] API key (overrides config file and environment)
    # @param base_url [String, nil] custom API base URL
    # @param workspace [String, nil] default workspace ID
    # @raise [ConfigurationError] if no valid API key is available
    def initialize(api_key: nil, base_url: nil, workspace: nil)
      @config = build_config(api_key, base_url, workspace)
      @config.validate!
      @connection = Superthread::Connection.new(@config)

      # Initialize resource accessors
      @users = Superthread::Resources::Users.new(self)
      @projects = Superthread::Resources::Projects.new(self)
      @spaces = Superthread::Resources::Spaces.new(self)
      @boards = Superthread::Resources::Boards.new(self)
      @cards = Superthread::Resources::Cards.new(self)
      @comments = Superthread::Resources::Comments.new(self)
      @pages = Superthread::Resources::Pages.new(self)
      @notes = Superthread::Resources::Notes.new(self)
      @sprints = Superthread::Resources::Sprints.new(self)
      @search = Superthread::Resources::Search.new(self)
      @tags = Superthread::Resources::Tags.new(self)
    end

    # Returns the resolved default workspace ID.
    #
    # @return [String, nil] workspace ID from configuration
    def default_workspace
      @config.workspace
    end

    # Resolves a workspace reference to an ID.
    #
    # @param workspace_ref [String] workspace alias or direct ID
    # @return [String] resolved workspace ID
    def resolve_workspace(workspace_ref)
      @config.resolve_workspace(workspace_ref)
    end

    # Makes an API request and returns raw hash data.
    #
    # Use this when you need the raw response before object conversion.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
    # @param path [String] API endpoint path relative to base URL (e.g., "/cards/123")
    # @param params [Hash{Symbol => Object}, nil] query parameters to include
    # @param body [Hash{Symbol => Object}, nil] request body to send as JSON
    # @return [Hash{Symbol => Object}] parsed JSON response
    # @raise [Superthread::ApiError] if the request fails
    def request(method:, path:, params: nil, body: nil)
      response = @connection.request(method: method, path: path, params: params, body: body)
      @last_response = response
      handle_response(response)
    end

    # Makes an API request and returns a typed object.
    #
    # This is the primary method used by resource classes.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
    # @param path [String] API endpoint path relative to base URL
    # @param params [Hash{Symbol => Object}, nil] query parameters to include
    # @param body [Hash{Symbol => Object}, nil] request body to send as JSON
    # @param object_class [Class, nil] class to instantiate for the response
    # @param unwrap_key [Symbol, nil] key to unwrap from response (e.g., :card extracts response[:card])
    # @return [Superthread::Object, Superthread::Model] response wrapped in appropriate object class
    # @raise [Superthread::ApiError] if the request fails
    def request_object(method:, path:, params: nil, body: nil, object_class: nil, unwrap_key: nil)
      data = request(method: method, path: path, params: params, body: body)
      convert_to_object(data, object_class: object_class, unwrap_key: unwrap_key)
    end

    # Makes an API request and returns a collection of objects.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
    # @param path [String] API endpoint path relative to base URL
    # @param params [Hash{Symbol => Object}, nil] query parameters to include
    # @param body [Hash{Symbol => Object}, nil] request body to send as JSON
    # @param item_class [Class, nil] class to instantiate for each item
    # @param items_key [Symbol, nil] key containing the items array (auto-detected if nil)
    # @return [Superthread::Objects::Collection] collection of objects
    # @raise [Superthread::ApiError] if the request fails
    def request_collection(method:, path:, params: nil, body: nil, item_class: nil, items_key: nil)
      data = request(method: method, path: path, params: params, body: body)
      Superthread::Objects::Collection.from_response(data, key: items_key, item_class: item_class)
    end

    # Converts raw hash data to a typed object.
    #
    # @param data [Hash{Symbol => Object}, Array<Hash>] raw response data
    # @param object_class [Class, nil] class to instantiate
    # @param unwrap_key [Symbol, nil] key to unwrap from response
    # @return [Superthread::Object, Superthread::Model, Array, Object] converted object(s)
    def convert_to_object(data, object_class: nil, unwrap_key: nil)
      # Unwrap nested response (e.g., { card: { ... } } -> { ... })
      data = data[unwrap_key] if unwrap_key && data.is_a?(Hash) && data.key?(unwrap_key)

      if object_class
        # Use Shale's from_response for Model subclasses
        if shale_model?(object_class)
          case data
          when Array
            object_class.from_response_array(data)
          when Hash
            object_class.from_response(data)
          else
            data
          end
        else
          # Legacy Superthread::Object pattern
          case data
          when Array
            data.map { |item| object_class.new(item) }
          when Hash
            object_class.new(data)
          else
            data
          end
        end
      else
        Superthread::Object.construct_from(data)
      end
    end

    # Checks if a class is a Shale-based Model.
    #
    # @param klass [Class] the class to check
    # @return [Boolean] true if the class is a Shale model
    def shale_model?(klass)
      klass.respond_to?(:shale_model?) && klass.shale_model?
    end

    private

    def build_config(api_key, base_url, workspace)
      config = Superthread::Configuration.new
      config.api_key = api_key if api_key
      config.base_url = base_url if base_url
      config.workspace = workspace if workspace
      config
    end

    def handle_response(response)
      case response.status
      when 200..299
        parse_response(response)
      else
        raise Superthread::ApiError.from_response(response)
      end
    end

    def parse_response(response)
      return {success: true} if response.status == 204

      body = response.body.to_s
      return {success: true} if body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      {success: true}
    end
  end
end
