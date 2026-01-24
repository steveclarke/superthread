# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st tags", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "tags create" do
    before do
      stub_api_post("test_workspace/tags", response: ApiFixtures::Tags::CREATE)
    end

    it "creates a new tag" do
      result = run_cli("tags", "create", "--name=urgent", "--color=#ff0000")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("urgent")
      expect(result[:stdout]).to include("tag-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("tags", "create", "--name=urgent", "--color=#ff0000")

      expect(json["id"]).to eq("tag-new-1")
      expect(json["name"]).to eq("urgent")
      expect(json["color"]).to eq("#ff0000")
    end
  end

  describe "tags update TAG" do
    before do
      stub_api_patch("test_workspace/tags/tag-1", response: ApiFixtures::Tags::UPDATE)
    end

    it "updates a tag" do
      result = run_cli("tags", "update", "tag-1", "--name=critical", "--color=#ff5500")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("critical")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("tags", "update", "tag-1", "--name=critical", "--color=#ff5500")

      expect(json["id"]).to eq("tag-1")
      expect(json["name"]).to eq("critical")
      expect(json["color"]).to eq("#ff5500")
    end
  end

  describe "tags delete TAG" do
    before do
      stub_api_delete("test_workspace/tags/tag-to-delete")
    end

    it "deletes a tag with --force" do
      result = run_cli("tags", "delete", "tag-to-delete", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Tag tag-to-delete deleted")
    end
  end
end
