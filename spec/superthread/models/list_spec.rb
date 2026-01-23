# frozen_string_literal: true

RSpec.describe Superthread::Models::List do
  let(:list_data) do
    {
      "id" => "list-123",
      "type" => "list",
      "board_id" => "board-456",
      "title" => "In Progress",
      "color" => "blue",
      "position" => 1,
      "user_id" => "user-789",
      "time_created" => 1_705_312_200_000,
      "time_updated" => 1_705_398_600_000
    }
  end

  subject(:list) { described_class.from_response(list_data) }

  describe ".from_response" do
    it "creates a list from hash data" do
      expect(list).to be_a(described_class)
      expect(list.id).to eq("list-123")
      expect(list.title).to eq("In Progress")
    end

    it "coerces types correctly" do
      expect(list.position).to eq(1)
      expect(list.position).to be_a(Integer)
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = list.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("list-123")
      expect(hash[:title]).to eq("In Progress")
    end
  end

  describe "#archived?" do
    it "returns false when not archived" do
      expect(list.archived?).to be false
    end

    it "returns true when archived" do
      archived_list = described_class.from_response(
        list_data.merge("archived" => {"user_id" => "user-1", "time_archived" => 1_705_312_200_000})
      )
      expect(archived_list.archived?).to be true
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(list.created_at).to be_a(Time)
      expect(list.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(list.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      list_without_times = described_class.from_response({"id" => "1"})
      expect(list_without_times.created_at).to be_nil
      expect(list_without_times.updated_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the list title" do
      expect(list.to_s).to eq("In Progress")
    end

    it "returns empty string when title is nil" do
      list_without_title = described_class.from_response({"id" => "1"})
      expect(list_without_title.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(list[:title]).to eq("In Progress")
      expect(list["color"]).to eq("blue")
    end

    it "supports key? check" do
      expect(list.key?(:title)).to be true
      expect(list.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      list2 = described_class.from_response(list_data)
      expect(list).to eq(list2)
    end

    it "returns false for different lists" do
      list2 = described_class.from_response(list_data.merge("id" => "different"))
      expect(list).not_to eq(list2)
    end
  end
end
