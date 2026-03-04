# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st tags", :cli do
  describe "tags list" do
    before do
      stub_api_get("test_workspace/tags", response: ApiFixtures::Tags::LIST)
    end

    it "lists available tags" do
      result = run_cli("tags", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("backend")
      expect(result[:stdout]).to include("frontend")
      expect(result[:stdout]).to include("bug")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("tags", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(3)
      expect(json.first).to have_key("name")
      expect(json.first).to have_key("color")
      expect(json.first).to have_key("total_cards")
    end
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
      stub_resolve_tags
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
      stub_resolve_tags(fixture: ApiFixtures::Tags::LIST_WITH_DELETE_TAG)
      stub_api_delete("test_workspace/tags/tag-to-delete")
    end

    it "deletes a tag with -y" do
      result = run_cli("tags", "delete", "tag-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Tag 'Tag to Delete' deleted")
    end
  end
end
