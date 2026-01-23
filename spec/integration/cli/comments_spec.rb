# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st comments", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "comments get COMMENT_ID" do
    it "displays comment details", vcr: {cassette_name: "cli/comments_get"} do
      result = run_cli("comments", "get", "comment-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("comment-1")
      expect(result[:stdout]).to include("This is a test comment")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/comments_get"} do
      json = cli_json("comments", "get", "comment-1")

      expect(json["id"]).to eq("comment-1")
      expect(json["content"]).to include("This is a test comment")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "comments create" do
    it "creates a comment on a card", vcr: {cassette_name: "cli/comments_create"} do
      result = run_cli("comments", "create",
        "--content=New comment content",
        "--card_id=card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("comment-new-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/comments_create"} do
      json = cli_json("comments", "create",
        "--content=New comment content",
        "--card_id=card-123")

      expect(json["id"]).to eq("comment-new-1")
      expect(json["content"]).to include("New comment content")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "comments update COMMENT_ID" do
    it "updates comment content", vcr: {cassette_name: "cli/comments_update"} do
      result = run_cli("comments", "update", "comment-1", "--content=Updated content")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("comment-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/comments_update"} do
      json = cli_json("comments", "update", "comment-1", "--content=Updated content")

      expect(json["id"]).to eq("comment-1")
      expect(json["content"]).to include("Updated content")
    end
  end

  describe "comments delete COMMENT_ID" do
    it "deletes a comment", vcr: {cassette_name: "cli/comments_delete"} do
      result = run_cli("comments", "delete", "comment-to-delete")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Comment comment-to-delete deleted")
    end
  end

  describe "comments reply COMMENT_ID" do
    it "replies to a comment", vcr: {cassette_name: "cli/comments_reply"} do
      result = run_cli("comments", "reply", "comment-1", "--content=This is a reply")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("reply-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/comments_reply"} do
      json = cli_json("comments", "reply", "comment-1", "--content=This is a reply")

      expect(json["id"]).to eq("reply-1")
      expect(json["content"]).to include("This is a reply")
    end
  end

  describe "comments replies COMMENT_ID" do
    it "lists replies to a comment", vcr: {cassette_name: "cli/comments_replies"} do
      result = run_cli("comments", "replies", "comment-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Reply 1")
      expect(result[:stdout]).to include("Reply 2")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/comments_replies"} do
      json = cli_json("comments", "replies", "comment-1")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
    end
  end

  describe "comments update_reply COMMENT_ID REPLY_ID" do
    it "updates a reply", vcr: {cassette_name: "cli/comments_update_reply"} do
      result = run_cli("comments", "update_reply", "comment-1", "reply-1",
        "--content=Updated reply")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("reply-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/comments_update_reply"} do
      json = cli_json("comments", "update_reply", "comment-1", "reply-1",
        "--content=Updated reply")

      expect(json["id"]).to eq("reply-1")
      expect(json["content"]).to include("Updated reply")
    end
  end

  describe "comments delete_reply COMMENT_ID REPLY_ID" do
    it "deletes a reply", vcr: {cassette_name: "cli/comments_delete_reply"} do
      result = run_cli("comments", "delete_reply", "comment-1", "reply-to-delete")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Reply reply-to-delete deleted")
    end
  end
end
