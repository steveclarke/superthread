# frozen_string_literal: true

module Superthread
  # Base class for API errors (HTTP responses).
  # Contains detailed information about the failed request.
  class ApiError < Error
    attr_reader :status, :body, :response

    # Creates an ApiError from HTTP response data.
    #
    # @param message [String] Error message
    # @param status [Integer] HTTP status code
    # @param body [String, Hash] Response body
    # @param response [Faraday::Response] Original response (optional)
    def initialize(message, status: nil, body: nil, response: nil)
      @status = status
      @body = body
      @response = response
      super(build_message(message))
    end

    # Factory method to create the appropriate error type from an HTTP response.
    # Examines both status code and body content to determine the best error class.
    #
    # @param response [Faraday::Response] The HTTP response
    # @return [Superthread::ApiError] The appropriate error subclass
    def self.from_response(response)
      status = response.status
      body = parse_body(response.body)
      message = extract_message(body)

      klass = error_class_for(status, body)
      klass.new(message, status: status, body: body, response: response)
    end

    # Determines the appropriate error class based on status and body.
    #
    # @param status [Integer] HTTP status code
    # @param body [Hash, String] Response body
    # @return [Class] Error class to use
    def self.error_class_for(status, body)
      case status
      when 400 then ValidationError
      when 401 then AuthenticationError
      when 403 then error_for_403(body)
      when 404 then NotFoundError
      when 422 then ValidationError
      when 429 then RateLimitError
      when 400..499 then ClientError
      when 500..599 then ServerError
      else ApiError
      end
    end

    # Handles 403 errors which may have different meanings based on body content.
    #
    # @param body [Hash, String] Response body
    # @return [Class] Specific error class
    def self.error_for_403(body)
      message = body.is_a?(Hash) ? body[:message].to_s : body.to_s

      case message.downcase
      when /rate limit/i then RateLimitError
      when /permission/i, /access denied/i then ForbiddenError
      else ForbiddenError
      end
    end

    # Parses the response body into a hash if possible.
    #
    # @param body [String] Raw response body
    # @return [Hash, String] Parsed body or original string
    def self.parse_body(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError
      body.to_s
    end

    # Extracts an error message from the response body.
    #
    # @param body [Hash, String] Response body
    # @return [String] Error message
    def self.extract_message(body)
      case body
      when Hash
        body[:message] || body[:error] || body[:error_description] || 'Unknown error'
      else
        body.to_s.empty? ? 'Unknown error' : body.to_s
      end
    end

    private

    def build_message(message)
      parts = []
      parts << "HTTP #{@status}" if @status
      parts << message
      parts.join(': ')
    end
  end

  # HTTP 4xx - Client errors (base class)
  class ClientError < ApiError; end

  # HTTP 5xx - Server errors
  class ServerError < ApiError; end

  # HTTP 401 - Invalid API key or authentication required
  class AuthenticationError < ClientError; end

  # HTTP 403 - Permission denied or forbidden action
  class ForbiddenError < ClientError; end

  # HTTP 404 - Resource not found
  class NotFoundError < ClientError; end

  # HTTP 400/422 - Validation error or invalid request
  class ValidationError < ClientError; end

  # HTTP 429 - Rate limit exceeded
  class RateLimitError < ClientError
    # Returns the number of seconds to wait before retrying.
    #
    # @return [Integer, nil] Seconds to wait, or nil if not available
    def retry_after
      return nil unless @response

      @response.headers['retry-after']&.to_i
    end
  end

  # Path/ID validation error (client-side validation)
  class PathValidationError < Error; end
end
