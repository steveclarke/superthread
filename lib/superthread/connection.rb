# frozen_string_literal: true

require "faraday"
require "json"

class Superthread::Connection
  def initialize(config)
    @config = config
    @connection = build_connection
  end

  def request(method:, path:, params: nil, body: nil)
    @connection.send(method) do |req|
      req.url(path)
      req.params = params if params
      req.body = body.to_json if body
    end
  end

  private

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
