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

  describe "#assigned_at" do
    it "converts assigned_date to Time" do
      expect(member.assigned_at).to be_a(Time)
      expect(member.assigned_at.year).to eq(2024)
    end

    it "returns nil when assigned_date is missing" do
      member_without_date = described_class.from_response({"user_id" => "user-1"})
      expect(member_without_date.assigned_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the user_id" do
      expect(member.to_s).to eq("user-123")
    end

    it "returns empty string when user_id is nil" do
      member_without_id = described_class.from_response({})
      expect(member_without_id.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(member[:user_id]).to eq("user-123")
      expect(member["role"]).to eq("assignee")
    end

    it "supports key? check" do
      expect(member.key?(:user_id)).to be true
      expect(member.key?(:nonexistent)).to be false
    end
  end
end
