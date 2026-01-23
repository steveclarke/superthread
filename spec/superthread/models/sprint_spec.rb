# frozen_string_literal: true

RSpec.describe Superthread::Models::Sprint do
  let(:sprint_data) do
    {
      'id' => 'sprint-123',
      'type' => 'sprint',
      'team_id' => 'team-456',
      'space_id' => 'space-789',
      'title' => 'Sprint 42',
      'description' => 'The meaning of sprints',
      'status' => 'active',
      'start_date' => 1_705_312_200_000,
      'due_date' => 1_706_521_800_000,
      'user_id' => 'user-001',
      'time_created' => 1_705_312_200_000,
      'time_updated' => 1_705_398_600_000
    }
  end

  subject(:sprint) { described_class.from_response(sprint_data) }

  describe '.from_response' do
    it 'creates a sprint from hash data' do
      expect(sprint).to be_a(described_class)
      expect(sprint.id).to eq('sprint-123')
      expect(sprint.title).to eq('Sprint 42')
      expect(sprint.status).to eq('active')
    end
  end

  describe '#to_h' do
    it 'returns a hash with symbol keys' do
      hash = sprint.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq('sprint-123')
      expect(hash[:title]).to eq('Sprint 42')
    end
  end

  describe 'status predicates' do
    describe '#active?' do
      it 'returns true when status is active' do
        expect(sprint.active?).to be true
      end

      it 'returns false when status is not active' do
        complete_sprint = described_class.from_response(sprint_data.merge('status' => 'complete'))
        expect(complete_sprint.active?).to be false
      end
    end

    describe '#complete?' do
      it 'returns true when status is complete' do
        complete_sprint = described_class.from_response(sprint_data.merge('status' => 'complete'))
        expect(complete_sprint.complete?).to be true
      end

      it 'returns false when status is not complete' do
        expect(sprint.complete?).to be false
      end
    end

    describe '#planned?' do
      it 'returns true when status is planned' do
        planned_sprint = described_class.from_response(sprint_data.merge('status' => 'planned'))
        expect(planned_sprint.planned?).to be true
      end

      it 'returns false when status is not planned' do
        expect(sprint.planned?).to be false
      end
    end
  end

  describe 'date helpers' do
    it 'converts start_date to Time' do
      expect(sprint.start_time).to be_a(Time)
      expect(sprint.start_time.year).to eq(2024)
    end

    it 'converts due_date to Time' do
      expect(sprint.due_time).to be_a(Time)
      expect(sprint.due_time.year).to eq(2024)
    end

    it 'returns nil for missing dates' do
      sprint_without_dates = described_class.from_response({ 'id' => '1' })
      expect(sprint_without_dates.start_time).to be_nil
      expect(sprint_without_dates.due_time).to be_nil
    end
  end

  describe 'time helpers' do
    it 'converts time_created to Time' do
      expect(sprint.created_at).to be_a(Time)
      expect(sprint.created_at.year).to eq(2024)
    end

    it 'converts time_updated to Time' do
      expect(sprint.updated_at).to be_a(Time)
    end

    it 'returns nil for missing times' do
      sprint_without_times = described_class.from_response({ 'id' => '1' })
      expect(sprint_without_times.created_at).to be_nil
      expect(sprint_without_times.updated_at).to be_nil
    end
  end

  describe '#to_s' do
    it 'returns the sprint title' do
      expect(sprint.to_s).to eq('Sprint 42')
    end

    it 'returns empty string when title is nil' do
      sprint_without_title = described_class.from_response({ 'id' => '1' })
      expect(sprint_without_title.to_s).to eq('')
    end
  end

  describe 'hash-like access' do
    it 'supports bracket access' do
      expect(sprint[:title]).to eq('Sprint 42')
      expect(sprint['status']).to eq('active')
    end

    it 'supports key? check' do
      expect(sprint.key?(:title)).to be true
      expect(sprint.key?(:nonexistent)).to be false
    end
  end

  describe '#==' do
    it 'compares by attributes' do
      sprint2 = described_class.from_response(sprint_data)
      expect(sprint).to eq(sprint2)
    end

    it 'returns false for different sprints' do
      sprint2 = described_class.from_response(sprint_data.merge('id' => 'different'))
      expect(sprint).not_to eq(sprint2)
    end
  end
end
