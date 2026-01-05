# frozen_string_literal: true

require "json"

class Superthread::Client
  # Resource accessors - composition pattern matching TypeScript structure
  attr_reader :users, :projects, :spaces, :boards, :cards,
              :comments, :pages, :notes, :sprints, :search, :tags

  def initialize(api_key: nil, base_url: nil, workspace: nil)
    @config = build_config(api_key, base_url, workspace)
    @config.validate!
    @connection = Superthread::Connection.new(@config)

    # Initialize resources (composition pattern from TypeScript)
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

  # Make an API request
  # @param method [Symbol] HTTP method (:get, :post, :patch, :delete)
  # @param path [String] API path
  # @param params [Hash] Query parameters (optional)
  # @param body [Hash] Request body (optional)
  # @return [Hash] Parsed JSON response
  def request(method:, path:, params: nil, body: nil)
    response = @connection.request(method: method, path: path, params: params, body: body)
    handle_response(response)
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
    when 401
      raise Superthread::AuthenticationError.new("Invalid API key", status: response.status, body: response.body)
    when 403
      raise Superthread::ForbiddenError.new("Permission denied", status: response.status, body: response.body)
    when 404
      raise Superthread::NotFoundError.new("Resource not found", status: response.status, body: response.body)
    when 400
      raise Superthread::ValidationError.new("Validation error: #{response.body}", status: response.status, body: response.body)
    when 429
      raise Superthread::RateLimitError.new("Rate limit exceeded", status: response.status, body: response.body)
    else
      raise Superthread::ApiError.new("API error (#{response.status}): #{response.body}", status: response.status, body: response.body)
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
