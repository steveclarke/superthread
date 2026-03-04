# frozen_string_literal: true

RSpec.describe Superthread::Models::Card do
  it_behaves_like "archivable" do
    let(:model_class) { described_class }
  end

  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "My Card Title" }
  end

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {
        time_created: :created_at,
        time_updated: :updated_at,
        start_date: :start_time,
        due_date: :due_time,
        completed_date: :completed_time
      }
    end
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :title }
    let(:hash_symbol_value) { "Test Card" }
    let(:hash_string_key) { "status" }
    let(:hash_string_value) { "started" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { card_data }
  end

  let(:card_data) do
    {
      "id" => "card-123",
      "title" => "Test Card",
      "status" => "started",
      "priority" => 4,  # 4=urgent, 3=high, 2=medium, 1=low
      "board_id" => "board-456",
      "board_title" => "Sprint Board",
      "list_id" => "list-789",
      "list_title" => "In Progress",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600,
      "is_watching" => true,
      "is_bookmarked" => false,
      "members" => [
        {"user_id" => "user-1", "role" => "assignee", "assigned_date" => 1_705_312_200}
      ],
      "tags" => [
        {"id" => "tag-1", "name" => "bug", "color" => "red"}
      ],
      "checklists" => [
        {
          "id" => "checklist-1",
          "title" => "Requirements",
          "items" => [
            {"id" => "item-1", "title" => "Write specs", "checked" => true},
            {"id" => "item-2", "title" => "Implement", "checked" => false}
          ]
        }
      ]
    }
  end

  subject(:card) { described_class.from_response(card_data) }

  describe ".from_response" do
    it "creates a card from hash data" do
      expect(card).to be_a(described_class)
      expect(card.id).to eq("card-123")
      expect(card.title).to eq("Test Card")
    end

    it "coerces types correctly" do
      expect(card.priority).to eq(4)  # 4=urgent
      expect(card.priority).to be_a(Integer)
      expect(card.time_created).to eq(1_705_312_200)
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = card.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("card-123")
      expect(hash[:title]).to eq("Test Card")
    end
  end

  describe "predicate methods" do
    it "returns watching status" do
      expect(card.watching?).to be true
    end

    it "returns bookmarked status" do
      expect(card.bookmarked?).to be false
    end

    it "returns archived status" do
      expect(card.archived?).to be false
    end
  end

  describe "#priority_name" do
    it "returns human-readable priority" do
      expect(card.priority_name).to eq("urgent")
    end

    it "returns nil for missing priority" do
      card_without_priority = described_class.from_response({"id" => "1"})
      expect(card_without_priority.priority_name).to be_nil
    end
  end

  describe "nested members" do
    it "parses members as Member objects" do
      expect(card.members).to be_an(Array)
      expect(card.members.first).to be_a(Superthread::Models::Member)
      expect(card.members.first.user_id).to eq("user-1")
      expect(card.members.first.role).to eq("assignee")
    end
  end

  describe "nested tags" do
    it "parses tags as Tag objects" do
      expect(card.tags).to be_an(Array)
      expect(card.tags.first).to be_a(Superthread::Models::Tag)
      expect(card.tags.first.name).to eq("bug")
      expect(card.tags.first.color).to eq("red")
    end
  end

  describe "nested checklists" do
    it "parses checklists as Checklist objects" do
      expect(card.checklists).to be_an(Array)
      expect(card.checklists.first).to be_a(Superthread::Models::Checklist)
      expect(card.checklists.first.title).to eq("Requirements")
    end

    it "parses checklist items" do
      checklist = card.checklists.first
      expect(checklist.items).to be_an(Array)
      expect(checklist.items.first).to be_a(Superthread::Models::ChecklistItem)
      expect(checklist.items.first.title).to eq("Write specs")
      expect(checklist.items.first.checked?).to be true
    end

    it "calculates checklist progress" do
      checklist = card.checklists.first
      expect(checklist.completed_count).to eq(1)
      expect(checklist.total_count).to eq(2)
      expect(checklist.progress).to eq(50.0)
      expect(checklist.complete?).to be false
    end
  end

  describe "card relationships" do
    describe "#parent" do
      it "returns nil when no parent_card" do
        expect(card.parent).to be_nil
      end

      it "returns CardRef when parent_card exists" do
        card_with_parent = described_class.from_response(
          card_data.merge("parent_card" => {"id" => "parent-1", "title" => "Parent Task"})
        )
        expect(card_with_parent.parent).to be_a(Superthread::Models::CardRef)
        expect(card_with_parent.parent.id).to eq("parent-1")
        expect(card_with_parent.parent.title).to eq("Parent Task")
        expect(card_with_parent.parent.to_s).to eq("Parent Task (parent-1)")
      end
    end

    describe "#children" do
      it "returns empty array when no child_cards" do
        expect(card.children).to eq([])
      end

      it "returns array of CardRef when child_cards exist" do
        card_with_children = described_class.from_response(
          card_data.merge("child_cards" => [
            {"id" => "child-1", "title" => "Subtask 1"},
            {"id" => "child-2", "title" => "Subtask 2"}
          ])
        )
        expect(card_with_children.children).to be_an(Array)
        expect(card_with_children.children.size).to eq(2)
        expect(card_with_children.children.first).to be_a(Superthread::Models::CardRef)
        expect(card_with_children.children.first.title).to eq("Subtask 1")
      end

      it "handles API format with card_id instead of id" do
        card_with_children = described_class.from_response(
          card_data.merge("child_cards" => [
            {"card_id" => "child-1", "title" => "Subtask 1", "board_id" => "18"}
          ])
        )
        expect(card_with_children.children.first.id).to eq("child-1")
      end
    end

    describe "#links" do
      it "returns empty array when no linked_cards" do
        expect(card.links).to eq([])
      end

      it "returns array of LinkedCardRef when linked_cards exist" do
        card_with_links = described_class.from_response(
          card_data.merge("linked_cards" => [
            {"id" => "link-1", "title" => "Blocking Task", "linked_card_type" => "blocks"},
            {"id" => "link-2", "title" => "Related Task", "linked_card_type" => "related"}
          ])
        )
        expect(card_with_links.links).to be_an(Array)
        expect(card_with_links.links.size).to eq(2)
        expect(card_with_links.links.first).to be_a(Superthread::Models::LinkedCardRef)
        expect(card_with_links.links.first.relationship).to eq("blocks")
      end
    end

    describe "#links_by_type" do
      it "groups links by relationship type" do
        card_with_links = described_class.from_response(
          card_data.merge("linked_cards" => [
            {"id" => "link-1", "title" => "Blocking Task 1", "linked_card_type" => "blocks"},
            {"id" => "link-2", "title" => "Blocking Task 2", "linked_card_type" => "blocks"},
            {"id" => "link-3", "title" => "Related Task", "linked_card_type" => "related"}
          ])
        )
        grouped = card_with_links.links_by_type
        expect(grouped.keys).to contain_exactly("blocks", "related")
        expect(grouped["blocks"].size).to eq(2)
        expect(grouped["related"].size).to eq(1)
      end
    end
  end
end
