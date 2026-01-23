# frozen_string_literal: true

RSpec.describe Superthread::Resources::Cards do
  let(:client) { Superthread::Client.new(api_key: "test_key") }

  describe "#update_checklist_item" do
    it "updates a checklist item", vcr: {cassette_name: "resources/cards_update_checklist_item"} do
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
    it "deletes a checklist item", vcr: {cassette_name: "resources/cards_delete_checklist_item"} do
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
    it "updates a checklist title", vcr: {cassette_name: "resources/cards_update_checklist"} do
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
    it "deletes a checklist", vcr: {cassette_name: "resources/cards_delete_checklist"} do
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
