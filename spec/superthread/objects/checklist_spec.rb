# frozen_string_literal: true

RSpec.describe Superthread::Objects::Checklist do
  let(:checklist_data) do
    {
      id: "checklist-123",
      title: "Requirements",
      content: "All requirements",
      card_id: "card-1",
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000,
      items: [
        {id: "item-1", title: "Write specs", checked: true},
        {id: "item-2", title: "Review code", checked: true},
        {id: "item-3", title: "Deploy", checked: false}
      ]
    }
  end

  subject(:checklist) { described_class.new(checklist_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(checklist.id).to eq("checklist-123")
      expect(checklist.title).to eq("Requirements")
      expect(checklist.content).to eq("All requirements")
      expect(checklist.card_id).to eq("card-1")
      expect(checklist.user_id).to eq("user-1")
      expect(checklist.time_created).to eq(1705312200000)
      expect(checklist.time_updated).to eq(1705398600000)
    end
  end

  describe "#items" do
    it "returns ChecklistItem objects" do
      items = checklist.items
      expect(items).to be_an(Array)
      expect(items.length).to eq(3)
      expect(items.first).to be_a(Superthread::Objects::ChecklistItem)
      expect(items.first.title).to eq("Write specs")
    end

    it "returns empty array when no items" do
      checklist = described_class.new({})
      expect(checklist.items).to eq([])
    end

    it "memoizes the result" do
      items1 = checklist.items
      items2 = checklist.items
      expect(items1).to equal(items2)
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(checklist.created_at).to be_a(Time)
      expect(checklist.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      checklist = described_class.new({})
      expect(checklist.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(checklist.updated_at).to be_a(Time)
      expect(checklist.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      checklist = described_class.new({})
      expect(checklist.updated_at).to be_nil
    end
  end

  describe "#completed_count" do
    it "returns count of checked items" do
      expect(checklist.completed_count).to eq(2)
    end

    it "returns 0 when no items" do
      checklist = described_class.new({})
      expect(checklist.completed_count).to eq(0)
    end
  end

  describe "#total_count" do
    it "returns total number of items" do
      expect(checklist.total_count).to eq(3)
    end

    it "returns 0 when no items" do
      checklist = described_class.new({})
      expect(checklist.total_count).to eq(0)
    end
  end

  describe "#progress" do
    it "returns percentage complete" do
      expect(checklist.progress).to eq(66.7)
    end

    it "returns 0.0 when no items" do
      checklist = described_class.new({})
      expect(checklist.progress).to eq(0.0)
    end

    it "returns 100.0 when all complete" do
      checklist = described_class.new(items: [{checked: true}, {checked: true}])
      expect(checklist.progress).to eq(100.0)
    end
  end

  describe "#complete?" do
    it "returns true when all items checked" do
      checklist = described_class.new(items: [{checked: true}, {checked: true}])
      expect(checklist.complete?).to be true
    end

    it "returns false when some items unchecked" do
      expect(checklist.complete?).to be false
    end

    it "returns false when no items" do
      checklist = described_class.new({})
      expect(checklist.complete?).to be false
    end
  end

  describe "type registration" do
    it "is registered as 'checklist' type" do
      expect(Superthread::Object.object_types["checklist"]).to eq(described_class)
    end
  end
end

RSpec.describe Superthread::Objects::ChecklistItem do
  let(:item_data) do
    {
      id: "item-123",
      title: "Write specs",
      content: "Unit tests",
      checklist_id: "checklist-1",
      user_id: "user-1",
      checked: true,
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:item) { described_class.new(item_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(item.id).to eq("item-123")
      expect(item.title).to eq("Write specs")
      expect(item.content).to eq("Unit tests")
      expect(item.checklist_id).to eq("checklist-1")
      expect(item.user_id).to eq("user-1")
      expect(item.checked).to be true
      expect(item.time_created).to eq(1705312200000)
      expect(item.time_updated).to eq(1705398600000)
    end
  end

  describe "#checked?" do
    it "returns true when checked" do
      expect(item.checked?).to be true
    end

    it "returns false when not checked" do
      item = described_class.new(checked: false)
      expect(item.checked?).to be false
    end

    it "returns false when checked is nil" do
      item = described_class.new({})
      expect(item.checked?).to be false
    end
  end

  describe "#complete?" do
    it "is an alias for checked?" do
      expect(item.complete?).to eq(item.checked?)
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(item.created_at).to be_a(Time)
      expect(item.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      item = described_class.new({})
      expect(item.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(item.updated_at).to be_a(Time)
      expect(item.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      item = described_class.new({})
      expect(item.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'checklist_item' type" do
      expect(Superthread::Object.object_types["checklist_item"]).to eq(described_class)
    end
  end
end
