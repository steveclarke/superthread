# frozen_string_literal: true

require "spec_helper"

RSpec.describe Superthread::Resources::Pages do
  include StubHelpers

  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#update_content" do
    before do
      stub_api_put("test_workspace/pages/page-42/content",
        response: {success: true})
    end

    it "updates page content via PUT endpoint" do
      result = client.pages.update_content(
        "test_workspace",
        "page-42",
        content: "<h1>Updated page</h1>"
      )

      expect(result[:success]).to be true
      expect(WebMock).to have_requested(:put, "https://api.superthread.com/v1/test_workspace/pages/page-42/content")
        .with(body: hash_including("content" => "<h1>Updated page</h1>", "is_html" => true))
    end
  end
end
