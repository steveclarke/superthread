# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st checklists", :cli do
  describe "checklists list --card" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::WITH_CHECKLIST)
    end

    it "lists checklists on a card" do
      result = run_cli("checklists", "list", "--card=card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checklist to Delete")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("checklists", "list", "--card=card-123")

      expect(json).to be_an(Array)
      expect(json.length).to eq(1)
      expect(json.first["title"]).to eq("Checklist to Delete")
    end
  end

  describe "checklists get CHECKLIST_ID" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::WITH_CHECKLIST)
    end

    it "displays checklist details" do
      result = run_cli("checklists", "get", "checklist-to-delete", "--card=card-123")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checklist to Delete")
      expect(result[:stdout]).to include("Item to Delete")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("checklists", "get", "checklist-to-delete", "--card=card-123")

      expect(json["id"]).to eq("checklist-to-delete")
      expect(json["title"]).to eq("Checklist to Delete")
    end
  end

  describe "checklists create" do
    before do
      stub_api_post("test_workspace/cards/card-123/checklists",
        response: {checklist: ApiFixtures::Cards::CHECKLIST_CREATE})
    end

    it "creates a checklist on a card" do
      result = run_cli("checklists", "create", "--card=card-123", "--title=Implementation Tasks")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implementation Tasks")
      expect(result[:stdout]).to include("checklist-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("checklists", "create", "--card=card-123", "--title=Implementation Tasks")

      expect(json["id"]).to eq("checklist-1")
      expect(json["title"]).to eq("Implementation Tasks")
      expect(json["card_id"]).to eq("card-123")
    end
  end

  describe "checklists update CHECKLIST_ID" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1",
        response: {checklist: ApiFixtures::Cards::CHECKLIST_UPDATE})
    end

    it "updates a checklist" do
      result = run_cli("checklists", "update", "checklist-1", "--card=card-123", "--title=Updated checklist")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated checklist")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("checklists", "update", "checklist-1", "--card=card-123", "--title=Updated checklist")

      expect(json["id"]).to eq("checklist-1")
      expect(json["title"]).to eq("Updated checklist")
    end
  end

  describe "checklists delete CHECKLIST_ID" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::WITH_CHECKLIST)
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-to-delete")
    end

    it "deletes a checklist with -y" do
      result = run_cli("checklists", "delete", "checklist-to-delete", "--card=card-123", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checklist 'Checklist to Delete' deleted")
    end
  end

  describe "checklists add-item CHECKLIST_ID" do
    before do
      stub_api_post("test_workspace/cards/card-123/checklists/checklist-1/items",
        response: {checklist_item: ApiFixtures::Cards::CHECKLIST_ITEM_CREATE})
    end

    it "adds an item to a checklist" do
      result = run_cli("checklists", "add-item", "checklist-1", "--card=card-123", "--title=Write unit tests")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Write unit tests")
      expect(result[:stdout]).to include("item-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("checklists", "add-item", "checklist-1", "--card=card-123", "--title=Write unit tests")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Write unit tests")
      expect(json["checked"]).to eq(false)
    end
  end

  describe "checklists update-item ITEM_ID" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-1",
        response: {checklist_item: ApiFixtures::Cards::CHECKLIST_ITEM_UPDATE})
    end

    it "updates a checklist item" do
      result = run_cli("checklists", "update-item", "item-1",
        "--card=card-123", "--checklist=checklist-1", "--title=Updated item")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated item")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("checklists", "update-item", "item-1",
        "--card=card-123", "--checklist=checklist-1", "--title=Updated item")

      expect(json["id"]).to eq("item-1")
      expect(json["title"]).to eq("Updated item")
      expect(json["checked"]).to eq(true)
    end
  end

  describe "checklists remove-item ITEM_ID" do
    before do
      stub_api_get("test_workspace/cards/card-123", response: ApiFixtures::Cards::WITH_CHECKLIST)
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-to-delete/items/item-to-delete")
    end

    it "deletes a checklist item with -y" do
      result = run_cli("checklists", "remove-item", "item-to-delete",
        "--card=card-123", "--checklist=checklist-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checklist item 'Item to Delete' deleted")
    end
  end

  describe "checklists check ITEM_ID [ITEM_ID...]" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-1",
        response: {checklist_item: ApiFixtures::Cards::CHECKLIST_ITEM_UPDATE})
    end

    it "marks an item as checked" do
      result = run_cli("checklists", "check", "item-1", "--card=card-123", "--checklist=checklist-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checked 1 item(s)")
    end

    it "marks multiple items as checked" do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-2",
        response: {checklist_item: ApiFixtures::Cards::CHECKLIST_ITEM_UPDATE})

      result = run_cli("checklists", "check", "item-1", "item-2", "--card=card-123", "--checklist=checklist-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Checked 2 item(s)")
    end
  end

  describe "checklists uncheck ITEM_ID [ITEM_ID...]" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-1",
        response: {checklist_item: ApiFixtures::Cards::CHECKLIST_ITEM_CREATE})
    end

    it "marks an item as unchecked" do
      result = run_cli("checklists", "uncheck", "item-1", "--card=card-123", "--checklist=checklist-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Unchecked 1 item(s)")
    end

    it "marks multiple items as unchecked" do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-2",
        response: {checklist_item: ApiFixtures::Cards::CHECKLIST_ITEM_CREATE})

      result = run_cli("checklists", "uncheck", "item-1", "item-2", "--card=card-123", "--checklist=checklist-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Unchecked 2 item(s)")
    end
  end
end
