# frozen_string_literal: true

require "spec_helper"

RSpec.describe Superthread::Resources::Cards do
  include StubHelpers

  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#update_checklist_item" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1/items/item-1",
        response: ApiFixtures::Cards::CHECKLIST_ITEM_UPDATE)
    end

    it "updates a checklist item" do
      result = client.cards.update_checklist_item(
        "test_workspace",
        "card-123",
        "checklist-1",
        "item-1",
        title: "Updated item",
        checked: true
      )

      expect(result).to be_a(Superthread::Models::ChecklistItem)
      expect(result.title).to eq("Updated item")
      expect(result.checked).to be true
    end
  end

  describe "#delete_checklist_item" do
    before do
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-1/items/item-1")
    end

    it "deletes a checklist item" do
      result = client.cards.delete_checklist_item(
        "test_workspace",
        "card-123",
        "checklist-1",
        "item-1"
      )

      expect(result).to be_a(Superthread::Object)
      expect(result[:success]).to be true
    end
  end

  describe "#update_checklist" do
    before do
      stub_api_patch("test_workspace/cards/card-123/checklists/checklist-1",
        response: ApiFixtures::Cards::CHECKLIST_UPDATE)
    end

    it "updates a checklist title" do
      result = client.cards.update_checklist(
        "test_workspace",
        "card-123",
        "checklist-1",
        title: "Updated checklist"
      )

      expect(result).to be_a(Superthread::Models::Checklist)
      expect(result.title).to eq("Updated checklist")
    end
  end

  describe "#delete_checklist" do
    before do
      stub_api_delete("test_workspace/cards/card-123/checklists/checklist-1")
    end

    it "deletes a checklist" do
      result = client.cards.delete_checklist(
        "test_workspace",
        "card-123",
        "checklist-1"
      )

      expect(result).to be_a(Superthread::Object)
      expect(result[:success]).to be true
    end
  end
end
