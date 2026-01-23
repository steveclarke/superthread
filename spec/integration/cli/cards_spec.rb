# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st cards", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "cards get CARD_ID" do
    it "displays card details", vcr: {cassette_name: "cli/cards_get"} do
      result = run_cli("cards", "get", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("started")
      expect(result[:stdout]).to include("In Progress")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_get"} do
      json = cli_json("cards", "get", "card-123")

      expect(json["id"]).to eq("card-123")
      expect(json["title"]).to eq("Implement feature X")
      expect(json["status"]).to eq("started")
      expect(json["priority"]).to eq(2)
      expect(json["members"]).to be_an(Array)
      expect(json["tags"]).to be_an(Array)
    end
  end

  describe "cards create" do
    it "creates a new card", vcr: {cassette_name: "cli/cards_create"} do
      result = run_cli("cards", "create",
        "--title=New card from CLI",
        "--list=101",
        "--board=10")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New card from CLI")
      expect(result[:stdout]).to include("card-new-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_create"} do
      json = cli_json("cards", "create",
        "--title=New card from CLI",
        "--list=101",
        "--board=10")

      expect(json["id"]).to eq("card-new-1")
      expect(json["title"]).to eq("New card from CLI")
      expect(json["status"]).to eq("not_started")
    end
  end

  describe "cards update CARD_ID" do
    it "updates card attributes", vcr: {cassette_name: "cli/cards_update"} do
      result = run_cli("cards", "update", "card-123",
        "--title=Updated card title",
        "--priority=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated card title")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_update"} do
      json = cli_json("cards", "update", "card-123",
        "--title=Updated card title",
        "--priority=1")

      expect(json["title"]).to eq("Updated card title")
      expect(json["priority"]).to eq(1)
    end
  end

  describe "cards delete CARD_ID" do
    it "deletes a card with --force", vcr: {cassette_name: "cli/cards_delete"} do
      result = run_cli("cards", "delete", "card-to-delete", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Card card-to-delete deleted")
    end
  end

  describe "cards duplicate CARD_ID" do
    it "duplicates a card", vcr: {cassette_name: "cli/cards_duplicate"} do
      result = run_cli("cards", "duplicate", "card-123",
        "--title=Copy of Implement feature X")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Copy of Implement feature X")
      expect(result[:stdout]).to include("card-dup-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_duplicate"} do
      json = cli_json("cards", "duplicate", "card-123",
        "--title=Copy of Implement feature X")

      expect(json["id"]).to eq("card-dup-1")
      expect(json["title"]).to eq("Copy of Implement feature X")
    end
  end

  describe "cards assigned USER" do
    it "lists cards assigned to user", vcr: {cassette_name: "cli/cards_assigned"} do
      result = run_cli("cards", "assigned", "u123abc")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("Fix bug Y")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_assigned"} do
      json = cli_json("cards", "assigned", "u123abc")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |c| c["title"] }).to include("Implement feature X", "Fix bug Y")
    end
  end

  describe "cards add_member CARD_ID USER" do
    it "adds a member to a card", vcr: {cassette_name: "cli/cards_add_member"} do
      result = run_cli("cards", "add_member", "card-123", "u456def")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Added u456def to card card-123")
    end
  end

  describe "cards remove_member CARD_ID USER" do
    it "removes a member from a card", vcr: {cassette_name: "cli/cards_remove_member"} do
      result = run_cli("cards", "remove_member", "card-123", "u456def")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed u456def from card card-123")
    end
  end

  describe "cards add_related CARD_ID RELATED_CARD_ID" do
    it "links two cards", vcr: {cassette_name: "cli/cards_add_related"} do
      result = run_cli("cards", "add_related", "card-123", "card-456", "--type=blocks")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Linked card card-123 -> card-456 (blocks)")
    end
  end

  describe "cards remove_related CARD_ID LINKED_CARD_ID" do
    it "removes card relationship", vcr: {cassette_name: "cli/cards_remove_related"} do
      result = run_cli("cards", "remove_related", "card-123", "card-456")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed link between card-123 and card-456")
    end
  end

  describe "cards checklist_create CARD_ID" do
    it "creates a checklist on a card", vcr: {cassette_name: "cli/cards_checklist_create"} do
      result = run_cli("cards", "checklist_create", "card-123",
        "--title=Implementation Tasks")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implementation Tasks")
      expect(result[:stdout]).to include("checklist-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_checklist_create"} do
      json = cli_json("cards", "checklist_create", "card-123",
        "--title=Implementation Tasks")

      expect(json["id"]).to eq("checklist-1")
      expect(json["title"]).to eq("Implementation Tasks")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "cards checklist_add_item CARD_ID CHECKLIST_ID" do
    it "adds item to checklist", vcr: {cassette_name: "cli/cards_checklist_add_item"} do
      result = run_cli("cards", "checklist_add_item", "card-123", "checklist-1",
        "--title=Write unit tests")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Write unit tests")
      expect(result[:stdout]).to include("item-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_checklist_add_item"} do
      json = cli_json("cards", "checklist_add_item", "card-123", "checklist-1",
        "--title=Write unit tests")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Write unit tests")
      expect(json["checked"]).to eq(false)
    end
  end

  describe "cards tags" do
    it "lists available tags", vcr: {cassette_name: "cli/cards_tags"} do
      result = run_cli("cards", "tags")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("backend")
      expect(result[:stdout]).to include("frontend")
      expect(result[:stdout]).to include("bug")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/cards_tags"} do
      json = cli_json("cards", "tags")

      expect(json).to be_an(Array)
      expect(json.length).to eq(3)
      expect(json.first).to have_key("name")
      expect(json.first).to have_key("color")
      expect(json.first).to have_key("total_cards")
    end
  end

  describe "cards add_tags CARD_ID TAGS" do
    it "adds tags to a card", vcr: {cassette_name: "cli/cards_add_tags"} do
      result = run_cli("cards", "add_tags", "card-123", "tag-2,tag-3")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Added 2 tag(s) to card card-123")
    end
  end

  describe "cards remove_tag CARD_ID TAG" do
    it "removes a tag from a card", vcr: {cassette_name: "cli/cards_remove_tag"} do
      result = run_cli("cards", "remove_tag", "card-123", "tag-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed tag tag-1 from card card-123")
    end
  end
end
