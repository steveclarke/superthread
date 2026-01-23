# frozen_string_literal: true

RSpec.describe Superthread::Objects::Note do
  let(:note_data) do
    {
      id: "note-123",
      type: "note",
      team_id: "team-1",
      title: "Meeting Notes",
      content: "<p>Discussed project updates</p>",
      user_id: "user-1",
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:note) { described_class.new(note_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(note.id).to eq("note-123")
      expect(note.type).to eq("note")
      expect(note.team_id).to eq("team-1")
      expect(note.title).to eq("Meeting Notes")
      expect(note.content).to eq("<p>Discussed project updates</p>")
      expect(note.user_id).to eq("user-1")
      expect(note.time_created).to eq(1705312200000)
      expect(note.time_updated).to eq(1705398600000)
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(note.created_at).to be_a(Time)
      expect(note.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      note = described_class.new({})
      expect(note.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(note.updated_at).to be_a(Time)
      expect(note.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      note = described_class.new({})
      expect(note.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'note' type" do
      expect(Superthread::Object.object_types["note"]).to eq(described_class)
    end
  end
end
