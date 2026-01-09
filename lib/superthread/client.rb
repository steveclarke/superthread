# frozen_string_literal: true

require 'json'

module Superthread
  class Client
    # Resource accessors for API endpoints
    attr_reader :users, :projects, :spaces, :boards, :cards,
                :comments, :pages, :notes, :sprints, :search, :tags

    # The last HTTP response received (for accessing headers, status, etc.)
    attr_reader :last_response

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

    # Access the resolved default workspace
    def default_workspace
      @config.workspace
    end

    # Resolve a workspace reference (alias or direct ID)
    def resolve_workspace(workspace_ref)
      @config.resolve_workspace(workspace_ref)
    end

    # Make an API request and return raw hash data.
    # Use this when you need the raw response before object conversion.
    #
    # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
    # @param path [String] API path
    # @param params [Hash] Query parameters (optional)
    # @param body [Hash] Request body (optional)
    # @return [Hash] Parsed JSON response as a hash
    def request(method:, path:, params: nil, body: nil)
      response = @connection.request(method: method, path: path, params: params, body: body)
      @last_response = response
      handle_response(response)
    end

    # Make an API request and return a Superthread::Object.
    # This is the primary method used by resource classes.
    #
    # @param method [Symbol] HTTP method
    # @param path [String] API path
    # @param params [Hash] Query parameters (optional)
    # @param body [Hash] Request body (optional)
    # @param object_class [Class] The class to use for the response (optional)
    # @param unwrap_key [Symbol] Key to unwrap from response (e.g., :card, :board)
    # @return [Superthread::Object] Response wrapped in appropriate object class
    def request_object(method:, path:, params: nil, body: nil, object_class: nil, unwrap_key: nil)
      data = request(method: method, path: path, params: params, body: body)
      convert_to_object(data, object_class: object_class, unwrap_key: unwrap_key)
    end

    # Make an API request and return a collection of objects.
    #
    # @param method [Symbol] HTTP method
    # @param path [String] API path
    # @param params [Hash] Query parameters (optional)
    # @param body [Hash] Request body (optional)
    # @param item_class [Class] The class to use for items (optional)
    # @param items_key [Symbol] Key containing the items array (optional, auto-detected)
    # @return [Superthread::Objects::Collection] Collection of objects
    def request_collection(method:, path:, params: nil, body: nil, item_class: nil, items_key: nil)
      data = request(method: method, path: path, params: params, body: body)
      Superthread::Objects::Collection.from_response(data, key: items_key, item_class: item_class)
    end

    # Convert raw hash data to a Superthread::Object.
    #
    # @param data [Hash, Array] Raw response data
    # @param object_class [Class] Optional class to use
    # @param unwrap_key [Symbol] Optional key to unwrap
    # @return [Superthread::Object, Array<Superthread::Object>]
    def convert_to_object(data, object_class: nil, unwrap_key: nil)
      # Unwrap nested response (e.g., { card: { ... } } -> { ... })
      data = data[unwrap_key] if unwrap_key && data.is_a?(Hash) && data.key?(unwrap_key)

      if object_class
        case data
        when Array
          data.map { |item| object_class.new(item) }
        when Hash
          object_class.new(data)
        else
          data
        end
      else
        Superthread::Object.construct_from(data)
      end
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
      return { success: true } if response.status == 204

      body = response.body.to_s
      return { success: true } if body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      { success: true }
    end
  end
end
