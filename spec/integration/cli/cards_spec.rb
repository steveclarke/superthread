# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st cards", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "cards get CARD_ID" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::GET)
    end

    it "displays card details" do
      result = run_cli("cards", "get", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("started")
      expect(result[:stdout]).to include("In Progress")
    end

    it "outputs JSON with --json flag" do
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
    before do
      stub_api_post("test_workspace/cards", response: ApiFixtures::Cards::CREATE)
    end

    it "creates a new card" do
      result = run_cli("cards", "create",
        "--title=New card from CLI",
        "--list=101",
        "--board=10")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New card from CLI")
      expect(result[:stdout]).to include("card-new-1")
    end

    it "outputs JSON with --json flag" do
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
    before do
      stub_api_patch("test_workspace/cards/card-123", response: ApiFixtures::Cards::UPDATE)
    end

    it "updates card attributes" do
      result = run_cli("cards", "update", "card-123",
        "--title=Updated card title",
        "--priority=1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated card title")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "update", "card-123",
        "--title=Updated card title",
        "--priority=1")

      expect(json["title"]).to eq("Updated card title")
      expect(json["priority"]).to eq(1)
    end
  end

  describe "cards delete CARD_ID" do
    before do
      stub_api_delete("test_workspace/cards/card-to-delete")
    end

    it "deletes a card with --force" do
      result = run_cli("cards", "delete", "card-to-delete", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Card card-to-delete deleted")
    end
  end

  describe "cards duplicate CARD_ID" do
    before do
      stub_api_post("test_workspace/cards/card-123/copy", response: ApiFixtures::Cards::DUPLICATE)
    end

    it "duplicates a card" do
      result = run_cli("cards", "duplicate", "card-123",
        "--title=Copy of Implement feature X")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Copy of Implement feature X")
      expect(result[:stdout]).to include("card-dup-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "duplicate", "card-123",
        "--title=Copy of Implement feature X")

      expect(json["id"]).to eq("card-dup-1")
      expect(json["title"]).to eq("Copy of Implement feature X")
    end
  end

  describe "cards assigned USER" do
    before do
      stub_api_post("test_workspace/views/preview", response: ApiFixtures::Cards::ASSIGNED)
    end

    it "lists cards assigned to user" do
      result = run_cli("cards", "assigned", "u123abc")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("Fix bug Y")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "assigned", "u123abc")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |c| c["title"] }).to include("Implement feature X", "Fix bug Y")
    end
  end

  describe "cards assign CARD_ID USER" do
    before do
      stub_api_post("test_workspace/cards/card-123/members", response: ApiFixtures::SUCCESS)
    end

    it "assigns a user to a card" do
      result = run_cli("cards", "assign", "card-123", "u456def")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Assigned u456def to card card-123")
    end
  end

  describe "cards unassign CARD_ID USER" do
    before do
      stub_api_delete("test_workspace/cards/card-123/members/u456def")
    end

    it "unassigns a user from a card" do
      result = run_cli("cards", "unassign", "card-123", "u456def")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Unassigned u456def from card card-123")
    end
  end

  describe "cards link CARD_ID RELATED_CARD_ID" do
    before do
      stub_api_post("test_workspace/cards/card-123/linked_cards", response: ApiFixtures::SUCCESS)
    end

    it "links two cards" do
      result = run_cli("cards", "link", "card-123", "card-456", "--type=blocks")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Linked card-123 -> card-456 (blocks)")
    end
  end

  describe "cards unlink CARD_ID LINKED_CARD_ID" do
    before do
      stub_api_delete("test_workspace/cards/card-123/linked_cards/card-456")
    end

    it "unlinks cards" do
      result = run_cli("cards", "unlink", "card-123", "card-456")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Unlinked card-123 from card-456")
    end
  end

  describe "cards add-checklist CARD_ID" do
    before do
      stub_api_post("test_workspace/cards/card-123/checklists", response: ApiFixtures::Cards::CHECKLIST_CREATE)
    end

    it "creates a checklist on a card" do
      result = run_cli("cards", "add-checklist", "card-123",
        "--title=Implementation Tasks")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implementation Tasks")
      expect(result[:stdout]).to include("checklist-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "add-checklist", "card-123",
        "--title=Implementation Tasks")

      expect(json["id"]).to eq("checklist-1")
      expect(json["title"]).to eq("Implementation Tasks")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "cards add-item CARD_ID CHECKLIST_ID" do
    before do
      stub_api_post("test_workspace/cards/card-123/checklists/checklist-1/items",
        response: ApiFixtures::Cards::CHECKLIST_ITEM_CREATE)
    end

    it "adds item to checklist" do
      result = run_cli("cards", "add-item", "card-123", "checklist-1",
        "--title=Write unit tests")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Write unit tests")
      expect(result[:stdout]).to include("item-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "add-item", "card-123", "checklist-1",
        "--title=Write unit tests")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Write unit tests")
      expect(json["checked"]).to eq(false)
    end
  end

  describe "cards edit-checklist CARD_ID CHECKLIST_ID" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1",
        response: ApiFixtures::Cards::CHECKLIST_UPDATE)
    end

    it "updates a checklist title" do
      result = run_cli("cards", "edit-checklist", "card-123", "checklist-1",
        "--title=Updated checklist")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated checklist")
      expect(result[:stdout]).to include("checklist-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "edit-checklist", "card-123", "checklist-1",
        "--title=Updated checklist")

      expect(json["id"]).to eq("checklist-1")
      expect(json["title"]).to eq("Updated checklist")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "cards rm-checklist CARD_ID CHECKLIST_ID" do
    before do
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-1")
    end

    it "deletes a checklist with --force" do
      result = run_cli("cards", "rm-checklist", "card-123", "checklist-1", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Deleted checklist checklist-1")
    end
  end

  describe "cards edit-item CARD_ID CHECKLIST_ID ITEM_ID" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-1",
        response: ApiFixtures::Cards::CHECKLIST_ITEM_UPDATE)
    end

    it "updates a checklist item" do
      result = run_cli("cards", "edit-item", "card-123", "checklist-1", "item-1",
        "--title=Updated item", "--checked")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated item")
      expect(result[:stdout]).to include("item-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "edit-item", "card-123", "checklist-1", "item-1",
        "--title=Updated item", "--checked")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Updated item")
      expect(json["checked"]).to eq(true)
    end
  end

  describe "cards rm-item CARD_ID CHECKLIST_ID ITEM_ID" do
    before do
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-1/items/item-1")
    end

    it "deletes a checklist item with --force" do
      result = run_cli("cards", "rm-item", "card-123", "checklist-1", "item-1", "--force")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Deleted checklist item item-1")
    end
  end

  describe "cards tags" do
    before do
      stub_api_get("test_workspace/tags", response: ApiFixtures::Tags::LIST)
    end

    it "lists available tags" do
      result = run_cli("cards", "tags")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("backend")
      expect(result[:stdout]).to include("frontend")
      expect(result[:stdout]).to include("bug")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "tags")

      expect(json).to be_an(Array)
      expect(json.length).to eq(3)
      expect(json.first).to have_key("name")
      expect(json.first).to have_key("color")
      expect(json.first).to have_key("total_cards")
    end
  end

  describe "cards tag CARD_ID TAGS" do
    before do
      stub_api_post("test_workspace/cards/card-123/tags", response: ApiFixtures::SUCCESS)
    end

    it "adds tags to a card" do
      result = run_cli("cards", "tag", "card-123", "tag-2,tag-3")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Added 2 tag(s) to card card-123")
    end
  end

  describe "cards untag CARD_ID TAG" do
    before do
      stub_api_delete("test_workspace/cards/card-123/tags/tag-1")
    end

    it "removes a tag from a card" do
      result = run_cli("cards", "untag", "card-123", "tag-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Removed tag tag-1 from card card-123")
    end
  end
end
