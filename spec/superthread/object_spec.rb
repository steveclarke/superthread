# frozen_string_literal: true

RSpec.describe Superthread::Object do
  describe "#initialize" do
    it "accepts hash data" do
      obj = described_class.new(id: "123", title: "Test")
      expect(obj[:id]).to eq("123")
    end

    it "symbolizes string keys" do
      obj = described_class.new("id" => "123")
      expect(obj[:id]).to eq("123")
    end

    it "accepts another Object" do
      original = described_class.new(id: "123")
      copy = described_class.new(original)
      expect(copy[:id]).to eq("123")
    end

    it "handles non-hash data" do
      obj = described_class.new("not a hash")
      expect(obj.data).to eq({})
    end
  end

  describe ".construct_from" do
    it "wraps hash in Object" do
      result = described_class.construct_from(id: "123")
      expect(result).to be_a(described_class)
    end

    it "wraps array items" do
      result = described_class.construct_from([{id: "1"}, {id: "2"}])
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to be_a(described_class)
    end

    it "returns non-hash/array values as-is" do
      expect(described_class.construct_from(nil)).to be_nil
      expect(described_class.construct_from("string")).to eq("string")
      expect(described_class.construct_from(123)).to eq(123)
    end

    it "uses registered type for typed objects" do
      # Objects::Tag is registered for type "tag"
      result = described_class.construct_from(type: "tag", name: "bug")
      expect(result).to be_a(Superthread::Objects::Tag)
    end
  end

  describe "#[]" do
    let(:obj) { described_class.new(id: "123", nested: {key: "value"}) }

    it "returns value for symbol key" do
      expect(obj[:id]).to eq("123")
    end

    it "returns value for string key" do
      expect(obj["id"]).to eq("123")
    end

    it "wraps nested hash in Object" do
      result = obj[:nested]
      expect(result).to be_a(described_class)
      expect(result[:key]).to eq("value")
    end
  end

  describe "#[]=" do
    let(:obj) { described_class.new }

    it "sets value" do
      obj[:id] = "123"
      expect(obj[:id]).to eq("123")
    end
  end

  describe "#each" do
    it "iterates over key-value pairs" do
      obj = described_class.new(a: 1, b: 2)
      pairs = []
      obj.each { |k, v| pairs << [k, v] }
      expect(pairs).to include([:a, 1])
      expect(pairs).to include([:b, 2])
    end
  end

  describe "#keys" do
    it "returns all keys" do
      obj = described_class.new(a: 1, b: 2)
      expect(obj.keys).to contain_exactly(:a, :b)
    end
  end

  describe "#values" do
    it "returns all values" do
      obj = described_class.new(a: 1, b: 2)
      expect(obj.values).to contain_exactly(1, 2)
    end
  end

  describe "#key?" do
    let(:obj) { described_class.new(id: "123") }

    it "returns true for existing key" do
      expect(obj.key?(:id)).to be true
      expect(obj.has_key?(:id)).to be true
    end

    it "returns false for missing key" do
      expect(obj.key?(:missing)).to be false
    end
  end

  describe "#to_h" do
    it "converts to plain hash" do
      obj = described_class.new(id: "123", title: "Test")
      expect(obj.to_h).to eq({id: "123", title: "Test"})
    end

    it "handles nested objects" do
      nested = described_class.new(key: "value")
      obj = described_class.new(id: "123", nested: nested)
      result = obj.to_h
      expect(result[:nested]).to eq({key: "value"})
    end

    it "handles arrays" do
      obj = described_class.new(items: [{a: 1}, {b: 2}])
      result = obj.to_h
      expect(result[:items]).to eq([{a: 1}, {b: 2}])
    end
  end

  describe "#to_json" do
    it "converts to JSON string" do
      obj = described_class.new(id: "123")
      json = obj.to_json
      expect(JSON.parse(json)).to eq({"id" => "123"})
    end
  end

  describe "#==" do
    it "equals another Object with same data" do
      obj1 = described_class.new(id: "123")
      obj2 = described_class.new(id: "123")
      expect(obj1).to eq(obj2)
    end

    it "equals hash with same data" do
      obj = described_class.new(id: "123")
      expect(obj).to eq({id: "123"})
    end

    it "does not equal different Object" do
      obj1 = described_class.new(id: "123")
      obj2 = described_class.new(id: "456")
      expect(obj1).not_to eq(obj2)
    end

    it "does not equal non-comparable types" do
      obj = described_class.new(id: "123")
      expect(obj).not_to eq("string")
    end
  end

  describe "#hash" do
    it "returns consistent hash code" do
      obj = described_class.new(id: "123")
      expect(obj.hash).to eq(obj.hash)
    end
  end

  describe "#inspect" do
    it "returns debug representation" do
      obj = described_class.new(id: "123")
      expect(obj.inspect).to include("Superthread::Object")
      expect(obj.inspect).to include("123")
    end
  end

  describe "method_missing" do
    let(:obj) { described_class.new(id: "123", title: "Test", archived: true) }

    it "provides getter access" do
      expect(obj.id).to eq("123")
      expect(obj.title).to eq("Test")
    end

    it "provides setter access" do
      obj.title = "New Title"
      expect(obj.title).to eq("New Title")
    end

    it "provides predicate methods" do
      expect(obj.archived?).to be true
    end

    it "returns false for missing predicate" do
      expect(obj.missing?).to be false
    end

    it "raises NoMethodError for truly missing methods" do
      expect { obj.nonexistent_method }.to raise_error(NoMethodError)
    end
  end

  describe "#respond_to_missing?" do
    let(:obj) { described_class.new(id: "123") }

    it "returns true for existing keys" do
      expect(obj.respond_to?(:id)).to be true
    end

    it "returns true for setters" do
      expect(obj.respond_to?(:id=)).to be true
    end

    it "returns true for predicates of existing keys" do
      expect(obj.respond_to?(:id?)).to be true
    end

    it "returns false for missing keys" do
      expect(obj.respond_to?(:missing)).to be false
    end
  end

  describe "type registration" do
    it "stores registered types" do
      expect(described_class.object_types).to be_a(Hash)
      expect(described_class.object_types["tag"]).to eq(Superthread::Objects::Tag)
    end
  end

  describe ".object_class_for" do
    it "returns registered class for known type" do
      klass = described_class.object_class_for(type: "tag")
      expect(klass).to eq(Superthread::Objects::Tag)
    end

    it "returns base Object for unknown type" do
      klass = described_class.object_class_for(type: "unknown")
      expect(klass).to eq(described_class)
    end

    it "returns base Object for missing type" do
      klass = described_class.object_class_for({})
      expect(klass).to eq(described_class)
    end
  end
end
