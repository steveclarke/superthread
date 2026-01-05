# frozen_string_literal: true

module Superthread
  # API errors (HTTP responses)
  class ApiError < Error
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  # HTTP 401 - Invalid API key
  class AuthenticationError < ApiError; end

  # HTTP 403 - Permission denied
  class ForbiddenError < ApiError; end

  # HTTP 404 - Resource not found
  class NotFoundError < ApiError; end

  # HTTP 400 - Validation error
  class ValidationError < ApiError; end

  # HTTP 429 - Rate limit exceeded
  class RateLimitError < ApiError; end

  # Path/ID validation error
  class PathValidationError < Error; end
end
