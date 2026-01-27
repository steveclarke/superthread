# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st comments", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "comments get COMMENT_ID" do
    before do
      stub_api_get("test_workspace/comments/comment-1", response: ApiFixtures::Comments::GET)
    end

    it "displays comment details" do
      result = run_cli("comments", "get", "comment-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("comment-1")
      expect(result[:stdout]).to include("This is a test comment")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("comments", "get", "comment-1")

      expect(json["id"]).to eq("comment-1")
      expect(json["content"]).to include("This is a test comment")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "comments create" do
    before do
      stub_api_post("test_workspace/comments", response: ApiFixtures::Comments::CREATE)
    end

    it "creates a comment on a card" do
      result = run_cli("comments", "create",
        "--content=New comment content",
        "--card=card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("comment-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("comments", "create",
        "--content=New comment content",
        "--card=card-123")

      expect(json["id"]).to eq("comment-new-1")
      expect(json["content"]).to include("New comment content")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "comments update COMMENT_ID" do
    before do
      stub_api_patch("test_workspace/comments/comment-1", response: ApiFixtures::Comments::UPDATE)
    end

    it "updates comment content" do
      result = run_cli("comments", "update", "comment-1", "--content=Updated content")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("comment-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("comments", "update", "comment-1", "--content=Updated content")

      expect(json["id"]).to eq("comment-1")
      expect(json["content"]).to include("Updated content")
    end
  end

  describe "comments delete COMMENT_ID" do
    before do
      stub_api_get("test_workspace/comments/comment-to-delete", response: ApiFixtures::Comments::DELETE)
      stub_api_delete("test_workspace/comments/comment-to-delete")
    end

    it "deletes a comment with -y" do
      result = run_cli("comments", "delete", "comment-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Comment comment-to-delete deleted")
    end
  end
end
