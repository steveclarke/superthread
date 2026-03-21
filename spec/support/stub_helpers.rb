# frozen_string_literal: true

module StubHelpers
  BASE_URL = "https://api.superthread.com/v1"

  # Stub a GET request returning JSON
  def stub_api_get(path, response:, status: 200, query: nil)
    stub = stub_request(:get, "#{BASE_URL}/#{path}")
    stub = stub.with(query: hash_including(query)) if query
    stub.to_return(
      status: status,
      body: response.to_json,
      headers: {"Content-Type" => "application/json"}
    )
  end

  # Stub a POST request returning JSON
  def stub_api_post(path, response:, status: 200, body: nil)
    stub = stub_request(:post, "#{BASE_URL}/#{path}")
    stub = stub.with(body: hash_including(body)) if body
    stub.to_return(
      status: status,
      body: response.to_json,
      headers: {"Content-Type" => "application/json"}
    )
  end

  # Stub a PATCH request returning JSON
  def stub_api_patch(path, response:, status: 200)
    stub_request(:patch, "#{BASE_URL}/#{path}")
      .to_return(
        status: status,
        body: response.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  # Stub a PUT request returning JSON
  def stub_api_put(path, response:, status: 200)
    stub_request(:put, "#{BASE_URL}/#{path}")
      .to_return(
        status: status,
        body: response.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  # Stub a DELETE request returning success
  def stub_api_delete(path, response: {success: true}, status: 200)
    stub_request(:delete, "#{BASE_URL}/#{path}")
      .to_return(
        status: status,
        body: response.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  # Stub an error response
  def stub_api_error(method, path, status:, error:)
    stub_request(method, "#{BASE_URL}/#{path}")
      .to_return(
        status: status,
        body: {error: error}.to_json,
        headers: {"Content-Type" => "application/json"}
      )
  end

  # Stub space name resolution (used by resolve_space in CLI commands)
  def stub_resolve_space
    stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
  end

  # Stub tag name resolution (used by resolve_tag in CLI commands)
  def stub_resolve_tags(fixture: ApiFixtures::Tags::LIST)
    stub_api_get("test_workspace/tags", response: fixture, query: {all: "true"})
  end
end

RSpec.configure do |config|
  config.include StubHelpers, :cli
  config.include StubHelpers, type: :integration
end
