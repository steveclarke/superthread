# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st replies", :cli do
  describe "replies list --comment" do
    before do
      stub_api_get("test_workspace/comments/comment-1/children", response: ApiFixtures::Comments::REPLIES)
    end

    it "lists replies to a comment" do
      result = run_cli("replies", "list", "--comment=comment-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Reply 1")
      expect(result[:stdout]).to include("Reply 2")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("replies", "list", "--comment=comment-1")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first["id"]).to eq("reply-1")
    end
  end

  describe "replies get REPLY_ID --comment" do
    before do
      stub_api_get("test_workspace/comments/comment-1/children", response: ApiFixtures::Comments::REPLIES)
    end

    it "displays reply details" do
      result = run_cli("replies", "get", "reply-1", "--comment=comment-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("reply-1")
      expect(result[:stdout]).to include("Reply 1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("replies", "get", "reply-1", "--comment=comment-1")

      expect(json["id"]).to eq("reply-1")
      expect(json["content"]).to include("Reply 1")
    end
  end

  describe "replies create" do
    before do
      stub_api_post("test_workspace/comments/comment-1/children", response: ApiFixtures::Comments::REPLY_CREATE)
    end

    it "creates a reply to a comment" do
      result = run_cli("replies", "create", "--comment=comment-1", "--content=This is a reply")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("reply-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("replies", "create", "--comment=comment-1", "--content=This is a reply")

      expect(json["id"]).to eq("reply-1")
      expect(json["content"]).to include("This is a reply")
    end
  end

  describe "replies update REPLY_ID" do
    before do
      stub_api_patch("test_workspace/comments/comment-1/children/reply-1",
        response: ApiFixtures::Comments::REPLY_UPDATE)
    end

    it "updates a reply" do
      result = run_cli("replies", "update", "reply-1", "--comment=comment-1", "--content=Updated reply")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated reply")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("replies", "update", "reply-1", "--comment=comment-1", "--content=Updated reply")

      expect(json["id"]).to eq("reply-1")
      expect(json["content"]).to include("Updated reply")
    end
  end

  describe "replies delete REPLY_ID" do
    before do
      stub_api_get("test_workspace/comments/comment-1/children",
        response: ApiFixtures::Comments::REPLIES_WITH_DELETE_TARGET)
      stub_api_delete("test_workspace/comments/comment-1/children/reply-to-delete")
    end

    it "deletes a reply with -y" do
      result = run_cli("replies", "delete", "reply-to-delete", "--comment=comment-1", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Reply reply-to-delete deleted")
    end
  end
end
