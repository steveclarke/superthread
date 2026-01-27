# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st cards", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "cards list with --since" do
    let(:now) { Time.new(2025, 1, 20, 12, 0, 0) }
    let(:today_ts) { Time.new(2025, 1, 20, 10, 0, 0).to_i * 1000 }
    let(:old_ts) { Time.new(2025, 1, 10, 10, 0, 0).to_i * 1000 }

    before do
      allow(Date).to receive(:today).and_return(now.to_date)
      allow(Time).to receive(:now).and_return(now)

      stub_api_post("test_workspace/views/preview", response: {
        cards: [
          {id: "card-1", title: "New Card", priority: 2, list_title: "To Do", time_created: today_ts, time_updated: today_ts},
          {id: "card-2", title: "Old Card", priority: 1, list_title: "Done", time_created: old_ts, time_updated: old_ts}
        ]
      })
    end

    it "filters cards by created date" do
      result = run_cli("cards", "list", "-b", "10", "--since=today")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Card")
      expect(result[:stdout]).not_to include("Old Card")
    end

    it "filters cards by updated date" do
      result = run_cli("cards", "list", "-b", "10", "--updated-since=today")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Card")
      expect(result[:stdout]).not_to include("Old Card")
    end

    it "accepts natural language dates" do
      result = run_cli("cards", "list", "-b", "10", "--since=friday")

      expect(result[:exit_code]).to eq(0)
      # Both cards should be included since Friday Jan 17 is before both
      expect(result[:stdout]).to include("New Card")
    end
  end

  describe "cards get CARD_ID" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::GET)
    end

    it "displays card details" do
      result = run_cli("cards", "get", "card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("In Progress")  # List name (colored by status)
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
      stub_api_get("test_workspace/cards/card-to-delete", response: ApiFixtures::Cards::DELETE)
      stub_api_delete("test_workspace/cards/card-to-delete")
    end

    it "deletes a card with -y" do
      result = run_cli("cards", "delete", "card-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Card 'Card to Delete' deleted")
    end
  end

  describe "cards duplicate CARD_ID" do
    before do
      stub_api_post("test_workspace/cards/card-123/copy", response: ApiFixtures::Cards::DUPLICATE)
      stub_api_get("test_workspace/boards/board-1", response: ApiFixtures::Boards::GET)
    end

    it "duplicates a card" do
      result = run_cli("cards", "duplicate", "card-123",
        "--title=Copy of Implement feature X", "--project=project-1", "-b", "board-1", "-l", "list-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Copy of Implement feature X")
      expect(result[:stdout]).to include("card-dup-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "duplicate", "card-123",
        "--title=Copy of Implement feature X", "--project=project-1", "-b", "board-1", "-l", "list-1")

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
      expect(result[:stdout]).to include("Assigned 1 user(s) to card card-123")
    end
  end

  describe "cards unassign CARD_ID USER" do
    before do
      stub_api_delete("test_workspace/cards/card-123/members/u456def")
    end

    it "unassigns a user from a card" do
      result = run_cli("cards", "unassign", "card-123", "u456def")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Unassigned 1 user(s) from card card-123")
    end
  end

  describe "cards link" do
    before do
      stub_api_post("test_workspace/cards/card-123/linked_cards", response: ApiFixtures::SUCCESS)
    end

    it "links two cards" do
      result = run_cli("cards", "link", "--card=card-123", "--related=card-456", "--type=blocks")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Linked card-123 -> card-456 (blocks)")
    end
  end

  describe "cards unlink" do
    before do
      stub_api_delete("test_workspace/cards/card-123/linked_cards/card-456")
    end

    it "unlinks cards" do
      result = run_cli("cards", "unlink", "--card=card-123", "--related=card-456")

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

  describe "cards add-item" do
    before do
      stub_api_post("test_workspace/cards/card-123/checklists/checklist-1/items",
        response: ApiFixtures::Cards::CHECKLIST_ITEM_CREATE)
    end

    it "adds item to checklist" do
      result = run_cli("cards", "add-item",
        "--card=card-123", "--checklist=checklist-1", "--title=Write unit tests")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Write unit tests")
      expect(result[:stdout]).to include("item-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "add-item",
        "--card=card-123", "--checklist=checklist-1", "--title=Write unit tests")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Write unit tests")
      expect(json["checked"]).to eq(false)
    end
  end

  describe "cards edit-checklist" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1",
        response: ApiFixtures::Cards::CHECKLIST_UPDATE)
    end

    it "updates a checklist title" do
      result = run_cli("cards", "edit-checklist",
        "--card=card-123", "--checklist=checklist-1", "--title=Updated checklist")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated checklist")
      expect(result[:stdout]).to include("checklist-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "edit-checklist",
        "--card=card-123", "--checklist=checklist-1", "--title=Updated checklist")

      expect(json["id"]).to eq("checklist-1")
      expect(json["title"]).to eq("Updated checklist")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "cards remove-checklist" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::WITH_CHECKLIST)
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-to-delete")
    end

    it "deletes a checklist with -y" do
      result = run_cli("cards", "remove-checklist",
        "--card=card-123", "--checklist=checklist-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checklist 'Checklist to Delete' deleted")
    end
  end

  describe "cards edit-item" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-1",
        response: ApiFixtures::Cards::CHECKLIST_ITEM_UPDATE)
    end

    it "updates a checklist item" do
      result = run_cli("cards", "edit-item",
        "--card=card-123", "--checklist=checklist-1", "--item=item-1",
        "--title=Updated item", "--checked")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated item")
      expect(result[:stdout]).to include("item-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("cards", "edit-item",
        "--card=card-123", "--checklist=checklist-1", "--item=item-1",
        "--title=Updated item", "--checked")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Updated item")
      expect(json["checked"]).to eq(true)
    end
  end

  describe "cards remove-item" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::WITH_CHECKLIST)
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-to-delete/items/item-to-delete")
    end

    it "deletes a checklist item with -y" do
      result = run_cli("cards", "remove-item",
        "--card=card-123", "--checklist=checklist-to-delete", "--item=item-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checklist item 'Item to Delete' deleted")
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
