# frozen_string_literal: true

RSpec.describe Superthread::Objects::Collection do
  describe ".from_response" do
    context "with array response" do
      it "wraps array in collection" do
        data = [{id: "1", title: "Item 1"}, {id: "2", title: "Item 2"}]
        collection = described_class.from_response(data)

        expect(collection.count).to eq(2)
        expect(collection.first[:id]).to eq("1")
      end
    end

    context "with hash response" do
      it "creates collection from hash" do
        data = {cards: [{id: "1"}, {id: "2"}]}
        collection = described_class.from_response(data, key: :cards)

        expect(collection.count).to eq(2)
      end
    end
  end

  describe "#initialize" do
    it "extracts items from specified key" do
      data = {cards: [{id: "1"}, {id: "2"}]}
      collection = described_class.new(data, key: :cards)

      expect(collection.count).to eq(2)
    end

    it "auto-detects items key" do
      data = {cards: [{id: "1"}, {id: "2"}]}
      collection = described_class.new(data)

      expect(collection.count).to eq(2)
    end

    it "auto-detects from various keys" do
      %i[items boards lists users projects spaces sprints pages notes comments tags members results data].each do |key|
        data = {key => [{id: "1"}]}
        collection = described_class.new(data)
        expect(collection.count).to eq(1), "Failed for key: #{key}"
      end
    end

    it "finds array value if no known key" do
      data = {unknown_key: [{id: "1"}]}
      collection = described_class.new(data)

      expect(collection.count).to eq(1)
    end

    it "handles non-hash data" do
      collection = described_class.new("not a hash")

      expect(collection.count).to eq(0)
    end

    it "wraps items with specified item_class" do
      data = {tags: [{id: "1", name: "bug", color: "red"}]}
      collection = described_class.new(data, key: :tags, item_class: Superthread::Objects::Tag)

      expect(collection.first).to be_a(Superthread::Objects::Tag)
      expect(collection.first.name).to eq("bug")
    end
  end

  describe "Enumerable methods" do
    let(:collection) do
      data = {items: [{id: "1", title: "First"}, {id: "2", title: "Second"}]}
      described_class.new(data, key: :items)
    end

    it "iterates with #each" do
      titles = []
      collection.each { |item| titles << item[:title] }
      expect(titles).to eq(["First", "Second"])
    end

    it "supports #map" do
      ids = collection.map { |item| item[:id] }
      expect(ids).to eq(["1", "2"])
    end

    it "supports #select" do
      selected = collection.select { |item| item[:id] == "1" }
      expect(selected.count).to eq(1)
    end
  end

  describe "#count / #size / #length" do
    let(:collection) do
      data = {items: [{id: "1"}, {id: "2"}, {id: "3"}]}
      described_class.new(data, key: :items)
    end

    it "returns item count" do
      expect(collection.count).to eq(3)
      expect(collection.size).to eq(3)
      expect(collection.length).to eq(3)
    end
  end

  describe "#empty?" do
    it "returns true for empty collection" do
      collection = described_class.new({items: []}, key: :items)
      expect(collection.empty?).to be true
    end

    it "returns false for non-empty collection" do
      collection = described_class.new({items: [{id: "1"}]}, key: :items)
      expect(collection.empty?).to be false
    end
  end

  describe "#first / #last" do
    let(:collection) do
      data = {items: [{id: "1"}, {id: "2"}, {id: "3"}]}
      described_class.new(data, key: :items)
    end

    it "returns first item" do
      expect(collection.first[:id]).to eq("1")
    end

    it "returns last item" do
      expect(collection.last[:id]).to eq("3")
    end
  end

  describe "#[]" do
    let(:collection) do
      data = {items: [{id: "1"}, {id: "2"}, {id: "3"}]}
      described_class.new(data, key: :items)
    end

    it "accesses by index" do
      expect(collection[0][:id]).to eq("1")
      expect(collection[1][:id]).to eq("2")
      expect(collection[-1][:id]).to eq("3")
    end
  end

  describe "#to_a / #to_ary" do
    let(:collection) do
      data = {items: [{id: "1"}, {id: "2"}]}
      described_class.new(data, key: :items)
    end

    it "converts to array" do
      array = collection.to_a
      expect(array).to be_an(Array)
      expect(array.count).to eq(2)
    end

    it "returns a copy" do
      array = collection.to_a
      array.clear
      expect(collection.count).to eq(2)
    end
  end

  describe "#to_h" do
    it "converts items to array of hashes" do
      data = {items: [{id: "1", title: "First"}, {id: "2", title: "Second"}]}
      collection = described_class.new(data, key: :items)

      result = collection.to_h
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Hash)
      expect(result.first[:id]).to eq("1")
    end
  end

  describe "#metadata" do
    it "returns non-item data" do
      data = {items: [{id: "1"}], total: 100, page: 1}
      collection = described_class.new(data, key: :items)

      expect(collection.metadata).to eq({total: 100, page: 1})
    end
  end

  describe "with Shale models" do
    it "uses from_response for shale models" do
      # Models::Tag is a Shale model
      data = {tags: [{id: "1", name: "bug", color: "red"}]}
      collection = described_class.new(data, key: :tags, item_class: Superthread::Models::Tag)

      expect(collection.first).to be_a(Superthread::Models::Tag)
      expect(collection.first.name).to eq("bug")
    end
  end
end
