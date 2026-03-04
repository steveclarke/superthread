# frozen_string_literal: true

RSpec.describe Superthread::Models::Member do
  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :user_id }
    let(:presentation_value) { "user-123" }
  end

  it_behaves_like "timestampable" do
    let(:model_class) { described_class }
    let(:timestamp_mappings) do
      {assigned_date: :assigned_at}
    end
  end

  it_behaves_like "hash accessible" do
    let(:hash_symbol_key) { :user_id }
    let(:hash_symbol_value) { "user-123" }
    let(:hash_string_key) { "role" }
    let(:hash_string_value) { "assignee" }
  end

  let(:member_data) do
    {
      "user_id" => "user-123",
      "role" => "assignee",
      "assigned_date" => 1_705_312_200
    }
  end

  subject(:member) { described_class.from_response(member_data) }

  describe ".from_response" do
    it "creates a member from hash data" do
      expect(member).to be_a(described_class)
      expect(member.user_id).to eq("user-123")
      expect(member.role).to eq("assignee")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = member.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:user_id]).to eq("user-123")
      expect(hash[:role]).to eq("assignee")
    end
  end
end
