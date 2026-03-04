# frozen_string_literal: true

RSpec.describe Superthread::Models::Note do
  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Meeting Notes" }
  end

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {
        time_created: :created_at,
        time_updated: :updated_at
      }
    end
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :title }
    let(:hash_symbol_value) { "Meeting Notes" }
    let(:hash_string_key) { "team_id" }
    let(:hash_string_value) { "team-456" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { note_data }
  end

  let(:note_data) do
    {
      "id" => "note-123",
      "type" => "note",
      "team_id" => "team-456",
      "title" => "Meeting Notes",
      "content" => "<p>Discussed the project timeline and deliverables.</p>",
      "user_id" => "user-001",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
    }
  end

  subject(:note) { described_class.from_response(note_data) }

  describe ".from_response" do
    it "creates a note from hash data" do
      expect(note).to be_a(described_class)
      expect(note.id).to eq("note-123")
      expect(note.title).to eq("Meeting Notes")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = note.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("note-123")
      expect(hash[:title]).to eq("Meeting Notes")
    end
  end
end
