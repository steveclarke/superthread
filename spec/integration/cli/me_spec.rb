# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st me", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
    stub_api_get("users/me", response: ApiFixtures::Users::ME)
  end

  it "displays current user info" do
    result = run_cli("me")

    expect(result[:exit_code]).to eq(0)
    expect(result[:stdout]).to include("Display Name")
    expect(result[:stdout]).to include("Test User")
    expect(result[:stdout]).to include("Email")
    expect(result[:stdout]).to include("test@example.com")
  end

  it "outputs JSON with --json flag" do
    json = cli_json("me")

    expect(json).to have_key("display_name")
    expect(json["display_name"]).to eq("Test User")
    expect(json["email"]).to eq("test@example.com")
  end
end
