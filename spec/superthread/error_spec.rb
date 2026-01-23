# frozen_string_literal: true

require "faraday"

RSpec.describe Superthread::Error do
  it "is a StandardError" do
    expect(described_class.new).to be_a(StandardError)
  end
end

RSpec.describe Superthread::ConfigurationError do
  it "is a Superthread::Error" do
    expect(described_class.new).to be_a(Superthread::Error)
  end
end

RSpec.describe Superthread::ApiError do
  subject(:error) { described_class.new("Not found", status: 404, body: {error: "Card not found"}) }

  it "is a Superthread::Error" do
    expect(error).to be_a(Superthread::Error)
  end

  it "stores the status code" do
    expect(error.status).to eq(404)
  end

  it "stores the response body" do
    expect(error.body).to eq({error: "Card not found"})
  end

  it "includes status in message" do
    expect(error.message).to include("Not found")
  end

  describe ".from_response" do
    let(:response) { instance_double(Faraday::Response, status: status, body: body, headers: {}) }

    context "with 400 status" do
      let(:status) { 400 }
      let(:body) { '{"message":"Invalid parameter"}' }

      it "returns a ValidationError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::ValidationError)
        expect(error.message).to include("Invalid parameter")
      end
    end

    context "with 401 status" do
      let(:status) { 401 }
      let(:body) { '{"message":"Invalid API key"}' }

      it "returns an AuthenticationError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::AuthenticationError)
      end
    end

    context "with 403 status" do
      let(:status) { 403 }
      let(:body) { '{"message":"Permission denied"}' }

      it "returns a ForbiddenError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::ForbiddenError)
      end
    end

    context "with 403 status and rate limit message" do
      let(:status) { 403 }
      let(:body) { '{"message":"Rate limit exceeded"}' }

      it "returns a RateLimitError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::RateLimitError)
      end
    end

    context "with 404 status" do
      let(:status) { 404 }
      let(:body) { '{"message":"Card not found"}' }

      it "returns a NotFoundError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::NotFoundError)
        expect(error.message).to include("Card not found")
      end
    end

    context "with 422 status" do
      let(:status) { 422 }
      let(:body) { '{"message":"Unprocessable entity"}' }

      it "returns a ValidationError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::ValidationError)
      end
    end

    context "with 429 status" do
      let(:status) { 429 }
      let(:body) { '{"message":"Too many requests"}' }

      it "returns a RateLimitError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::RateLimitError)
      end
    end

    context "with 500 status" do
      let(:status) { 500 }
      let(:body) { '{"message":"Internal server error"}' }

      it "returns a ServerError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::ServerError)
      end
    end

    context "with other 4xx status" do
      let(:status) { 418 }
      let(:body) { '{"message":"I am a teapot"}' }

      it "returns a ClientError" do
        error = described_class.from_response(response)
        expect(error).to be_a(Superthread::ClientError)
      end
    end

    context "with unknown status" do
      let(:status) { 300 }
      let(:body) { '{"message":"Redirected"}' }

      it "returns a base ApiError" do
        error = described_class.from_response(response)
        expect(error.class).to eq(Superthread::ApiError)
      end
    end

    context "with invalid JSON body" do
      let(:status) { 500 }
      let(:body) { "Internal Server Error" }

      it "uses body as message" do
        error = described_class.from_response(response)
        expect(error.message).to include("Internal Server Error")
      end
    end

    context "with empty body" do
      let(:status) { 500 }
      let(:body) { "" }

      it "uses unknown error message" do
        error = described_class.from_response(response)
        expect(error.message).to include("Unknown error")
      end
    end

    context "with error key instead of message" do
      let(:status) { 400 }
      let(:body) { '{"error":"Something went wrong"}' }

      it "extracts error from body" do
        error = described_class.from_response(response)
        expect(error.message).to include("Something went wrong")
      end
    end

    context "with error_description key" do
      let(:status) { 400 }
      let(:body) { '{"error_description":"OAuth error occurred"}' }

      it "extracts error_description from body" do
        error = described_class.from_response(response)
        expect(error.message).to include("OAuth error occurred")
      end
    end
  end

  describe ".error_for_403" do
    it "returns RateLimitError for rate limit message" do
      body = {message: "Rate limit exceeded"}
      expect(described_class.error_for_403(body)).to eq(Superthread::RateLimitError)
    end

    it "returns ForbiddenError for permission message" do
      body = {message: "Permission denied"}
      expect(described_class.error_for_403(body)).to eq(Superthread::ForbiddenError)
    end

    it "returns ForbiddenError for access denied message" do
      body = {message: "Access denied"}
      expect(described_class.error_for_403(body)).to eq(Superthread::ForbiddenError)
    end

    it "returns ForbiddenError for other messages" do
      body = {message: "Something else"}
      expect(described_class.error_for_403(body)).to eq(Superthread::ForbiddenError)
    end

    it "handles string body" do
      expect(described_class.error_for_403("Rate limit")).to eq(Superthread::RateLimitError)
    end
  end

  describe ".parse_body" do
    it "parses valid JSON" do
      result = described_class.parse_body('{"key":"value"}')
      expect(result).to eq({key: "value"})
    end

    it "returns empty hash for nil" do
      expect(described_class.parse_body(nil)).to eq({})
    end

    it "returns empty hash for empty string" do
      expect(described_class.parse_body("")).to eq({})
    end

    it "returns original string for invalid JSON" do
      expect(described_class.parse_body("not json")).to eq("not json")
    end
  end

  describe ".extract_message" do
    it "extracts message from hash" do
      expect(described_class.extract_message({message: "Error"})).to eq("Error")
    end

    it "extracts error from hash" do
      expect(described_class.extract_message({error: "Error"})).to eq("Error")
    end

    it "extracts error_description from hash" do
      expect(described_class.extract_message({error_description: "Error"})).to eq("Error")
    end

    it "returns Unknown error for empty hash" do
      expect(described_class.extract_message({})).to eq("Unknown error")
    end

    it "returns string body as-is" do
      expect(described_class.extract_message("Error text")).to eq("Error text")
    end

    it "returns Unknown error for empty string" do
      expect(described_class.extract_message("")).to eq("Unknown error")
    end
  end
end

RSpec.describe Superthread::AuthenticationError do
  it "is an ApiError" do
    expect(described_class.new("Unauthorized")).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::ForbiddenError do
  it "is a ClientError" do
    expect(described_class.new("Forbidden")).to be_a(Superthread::ClientError)
  end
end

RSpec.describe Superthread::NotFoundError do
  it "is an ApiError" do
    expect(described_class.new("Not found")).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::ValidationError do
  it "is an ApiError" do
    expect(described_class.new("Invalid params")).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::RateLimitError do
  it "is an ApiError" do
    expect(described_class.new("Too many requests")).to be_a(Superthread::ApiError)
  end

  describe "#retry_after" do
    it "returns nil when no response" do
      error = described_class.new("Too many requests")
      expect(error.retry_after).to be_nil
    end

    it "returns retry-after header value" do
      response = instance_double(Faraday::Response, headers: {"retry-after" => "60"})
      error = described_class.new("Too many requests", response: response)
      expect(error.retry_after).to eq(60)
    end

    it "returns nil when header missing" do
      response = instance_double(Faraday::Response, headers: {})
      error = described_class.new("Too many requests", response: response)
      expect(error.retry_after).to be_nil
    end
  end
end

RSpec.describe Superthread::ClientError do
  it "is an ApiError" do
    expect(described_class.new("Client error")).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::ServerError do
  it "is an ApiError" do
    expect(described_class.new("Server error")).to be_a(Superthread::ApiError)
  end
end

RSpec.describe Superthread::PathValidationError do
  it "is a Superthread::Error" do
    expect(described_class.new("Invalid path")).to be_a(Superthread::Error)
  end
end
