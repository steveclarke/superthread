# frozen_string_literal: true

RSpec.describe Superthread::Models::Note do
  let(:note_data) do
    {
      'id' => 'note-123',
      'type' => 'note',
      'team_id' => 'team-456',
      'title' => 'Meeting Notes',
      'content' => '<p>Discussed the project timeline and deliverables.</p>',
      'user_id' => 'user-001',
      'time_created' => 1_705_312_200_000,
      'time_updated' => 1_705_398_600_000
    }
  end

  subject(:note) { described_class.from_response(note_data) }

  describe '.from_response' do
    it 'creates a note from hash data' do
      expect(note).to be_a(described_class)
      expect(note.id).to eq('note-123')
      expect(note.title).to eq('Meeting Notes')
    end
  end

  describe '#to_h' do
    it 'returns a hash with symbol keys' do
      hash = note.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq('note-123')
      expect(hash[:title]).to eq('Meeting Notes')
    end
  end

  describe 'time helpers' do
    it 'converts time_created to Time' do
      expect(note.created_at).to be_a(Time)
      expect(note.created_at.year).to eq(2024)
    end

    it 'converts time_updated to Time' do
      expect(note.updated_at).to be_a(Time)
    end

    it 'returns nil for missing times' do
      note_without_times = described_class.from_response({ 'id' => '1' })
      expect(note_without_times.created_at).to be_nil
      expect(note_without_times.updated_at).to be_nil
    end
  end

  describe '#to_s' do
    it 'returns the note title' do
      expect(note.to_s).to eq('Meeting Notes')
    end

    it 'returns empty string when title is nil' do
      note_without_title = described_class.from_response({ 'id' => '1' })
      expect(note_without_title.to_s).to eq('')
    end
  end

  describe 'hash-like access' do
    it 'supports bracket access' do
      expect(note[:title]).to eq('Meeting Notes')
      expect(note['team_id']).to eq('team-456')
    end

    it 'supports key? check' do
      expect(note.key?(:title)).to be true
      expect(note.key?(:nonexistent)).to be false
    end
  end

  describe '#==' do
    it 'compares by attributes' do
      note2 = described_class.from_response(note_data)
      expect(note).to eq(note2)
    end

    it 'returns false for different notes' do
      note2 = described_class.from_response(note_data.merge('id' => 'different'))
      expect(note).not_to eq(note2)
    end
  end
end
