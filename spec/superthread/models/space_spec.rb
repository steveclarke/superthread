# frozen_string_literal: true

RSpec.describe Superthread::Models::Space do
  let(:space_data) do
    {
      'id' => 'space-123',
      'type' => 'space',
      'team_id' => 'team-456',
      'title' => 'Engineering',
      'description' => 'Engineering team space',
      'icon' => 'code',
      'user_id' => 'user-001',
      'time_created' => 1_705_312_200_000,
      'time_updated' => 1_705_398_600_000,
      'members' => [
        { 'user_id' => 'user-1', 'role' => 'admin', 'assigned_date' => 1_705_312_200_000 },
        { 'user_id' => 'user-2', 'role' => 'member', 'assigned_date' => 1_705_398_600_000 }
      ]
    }
  end

  subject(:space) { described_class.from_response(space_data) }

  describe '.from_response' do
    it 'creates a space from hash data' do
      expect(space).to be_a(described_class)
      expect(space.id).to eq('space-123')
      expect(space.title).to eq('Engineering')
    end
  end

  describe '#to_h' do
    it 'returns a hash with symbol keys' do
      hash = space.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq('space-123')
      expect(hash[:title]).to eq('Engineering')
    end
  end

  describe '#archived?' do
    it 'returns false when not archived' do
      expect(space.archived?).to be false
    end

    it 'returns true when archived' do
      archived_space = described_class.from_response(
        space_data.merge('archived' => { 'user_id' => 'user-1', 'time_archived' => 1_705_312_200_000 })
      )
      expect(archived_space.archived?).to be true
    end
  end

  describe 'time helpers' do
    it 'converts time_created to Time' do
      expect(space.created_at).to be_a(Time)
      expect(space.created_at.year).to eq(2024)
    end

    it 'converts time_updated to Time' do
      expect(space.updated_at).to be_a(Time)
    end

    it 'returns nil for missing times' do
      space_without_times = described_class.from_response({ 'id' => '1' })
      expect(space_without_times.created_at).to be_nil
      expect(space_without_times.updated_at).to be_nil
    end
  end

  describe 'nested members' do
    it 'parses members as Member objects' do
      expect(space.members).to be_an(Array)
      expect(space.members.length).to eq(2)
      expect(space.members.first).to be_a(Superthread::Models::Member)
    end

    it 'preserves member data' do
      member = space.members.first
      expect(member.user_id).to eq('user-1')
      expect(member.role).to eq('admin')
    end
  end

  describe '#to_s' do
    it 'returns the space title' do
      expect(space.to_s).to eq('Engineering')
    end

    it 'returns empty string when title is nil' do
      space_without_title = described_class.from_response({ 'id' => '1' })
      expect(space_without_title.to_s).to eq('')
    end
  end

  describe 'hash-like access' do
    it 'supports bracket access' do
      expect(space[:title]).to eq('Engineering')
      expect(space['description']).to eq('Engineering team space')
    end

    it 'supports key? check' do
      expect(space.key?(:title)).to be true
      expect(space.key?(:nonexistent)).to be false
    end
  end

  describe '#==' do
    it 'compares by attributes' do
      space2 = described_class.from_response(space_data)
      expect(space).to eq(space2)
    end

    it 'returns false for different spaces' do
      space2 = described_class.from_response(space_data.merge('id' => 'different'))
      expect(space).not_to eq(space2)
    end
  end
end
