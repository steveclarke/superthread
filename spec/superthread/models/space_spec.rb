# frozen_string_literal: true

RSpec.describe Superthread::Models::Space do
  it_behaves_like "archivable" do
    let(:model_class) { described_class }
  end

  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :title }
    let(:presentation_value) { "Engineering" }
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
    let(:hash_symbol_value) { "Engineering" }
    let(:hash_string_key) { "description" }
    let(:hash_string_value) { "Engineering team space" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { space_data }
  end

  let(:space_data) do
    {
      "id" => "space-123",
      "type" => "space",
      "team_id" => "team-456",
      "title" => "Engineering",
      "description" => "Engineering team space",
      "icon" => "code",
      "user_id" => "user-001",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600,
      "members" => [
        {"user_id" => "user-1", "role" => "admin", "assigned_date" => 1_705_312_200},
        {"user_id" => "user-2", "role" => "member", "assigned_date" => 1_705_398_600}
      ]
    }
  end

  subject(:space) { described_class.from_response(space_data) }

  describe ".from_response" do
    it "creates a space from hash data" do
      expect(space).to be_a(described_class)
      expect(space.id).to eq("space-123")
      expect(space.title).to eq("Engineering")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = space.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("space-123")
      expect(hash[:title]).to eq("Engineering")
    end
  end

  describe "nested members" do
    it "parses members as Member objects" do
      expect(space.members).to be_an(Array)
      expect(space.members.length).to eq(2)
      expect(space.members.first).to be_a(Superthread::Models::Member)
    end

    it "preserves member data" do
      member = space.members.first
      expect(member.user_id).to eq("user-1")
      expect(member.role).to eq("admin")
    end
  end
end
