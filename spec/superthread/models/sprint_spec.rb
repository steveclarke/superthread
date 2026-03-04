# frozen_string_literal: true

RSpec.describe Superthread::Models::Sprint do
  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Sprint 42" }
  end

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {
        time_created: :created_at,
        time_updated: :updated_at,
        start_date: :start_time
      }
    end
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :title }
    let(:hash_symbol_value) { "Sprint 42" }
    let(:hash_string_key) { "team_id" }
    let(:hash_string_value) { "team-456" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { sprint_data }
  end

  let(:sprint_data) do
    {
      "id" => "sprint-123",
      "team_id" => "team-456",
      "title" => "Sprint 42",
      "start_date" => 1_705_312_200,
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
    }
  end

  subject(:sprint) { described_class.from_response(sprint_data) }

  describe ".from_response" do
    it "creates a sprint from hash data" do
      expect(sprint).to be_a(described_class)
      expect(sprint.id).to eq("sprint-123")
      expect(sprint.title).to eq("Sprint 42")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = sprint.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("sprint-123")
      expect(hash[:title]).to eq("Sprint 42")
    end
  end
end
