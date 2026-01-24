# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st spaces", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "spaces list" do
    before do
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
    end

    it "lists all spaces" do
      result = run_cli("spaces", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Engineering")
      expect(result[:stdout]).to include("Design")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("spaces", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |s| s["title"] }).to include("Engineering", "Design")
    end
  end

  describe "spaces get SPACE_ID" do
    before do
      stub_api_get("test_workspace/projects/1", response: ApiFixtures::Spaces::GET)
    end

    it "displays space details" do
      result = run_cli("spaces", "get", "1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Engineering")
      expect(result[:stdout]).to include("Engineering team space")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("spaces", "get", "1")

      expect(json["id"]).to eq("1")
      expect(json["title"]).to eq("Engineering")
      expect(json["description"]).to eq("Engineering team space")
    end
  end

  describe "spaces create" do
    before do
      stub_api_post("test_workspace/projects", response: ApiFixtures::Spaces::CREATE)
    end

    it "creates a new space" do
      result = run_cli("spaces", "create", "--title=Marketing", "--description=Marketing team space")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Marketing")
      expect(result[:stdout]).to include("space-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("spaces", "create", "--title=Marketing", "--description=Marketing team space")

      expect(json["id"]).to eq("space-new-1")
      expect(json["title"]).to eq("Marketing")
      expect(json["description"]).to eq("Marketing team space")
    end
  end

  describe "spaces update SPACE_ID" do
    before do
      stub_api_patch("test_workspace/projects/1", response: ApiFixtures::Spaces::UPDATE)
    end

    it "updates space attributes" do
      result = run_cli("spaces", "update", "1", "--title=Engineering Team")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Engineering Team")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("spaces", "update", "1", "--title=Engineering Team")

      expect(json["id"]).to eq("1")
      expect(json["title"]).to eq("Engineering Team")
    end
  end

  describe "spaces delete SPACE_ID" do
    before do
      stub_api_get("test_workspace/projects/space-to-delete", response: ApiFixtures::Spaces::DELETE)
      stub_api_delete("test_workspace/projects/space-to-delete")
    end

    it "deletes a space with --force" do
      result = run_cli("spaces", "delete", "space-to-delete", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Space 'Space to Delete' deleted")
    end
  end

  describe "spaces add_member SPACE_ID USER_ID" do
    before do
      stub_api_post("test_workspace/projects/1/members", response: ApiFixtures::Spaces::ADD_MEMBER)
    end

    it "adds a member to a space" do
      result = run_cli("spaces", "add_member", "1", "user-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Added user-123 to space 1")
    end
  end

  describe "spaces add_member with role" do
    before do
      stub_api_post("test_workspace/projects/1/members", response: ApiFixtures::Spaces::ADD_MEMBER_ROLE)
    end

    it "adds a member with role" do
      result = run_cli("spaces", "add_member", "1", "user-123", "--role=admin")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Added user-123 to space 1")
    end
  end

  describe "spaces remove_member SPACE_ID MEMBER_ID" do
    before do
      stub_api_delete("test_workspace/projects/1/members/member-123")
    end

    it "removes a member from a space" do
      result = run_cli("spaces", "remove_member", "1", "member-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed member-123 from space 1")
    end
  end
end
