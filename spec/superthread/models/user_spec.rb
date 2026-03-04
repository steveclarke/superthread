# frozen_string_literal: true

RSpec.describe Superthread::Models::User do
  it_behaves_like "presentable" do
    let(:model_class) { described_class }
    let(:presentation_attribute) { :display_name }
    let(:presentation_value) { "John Doe" }
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
    let(:hash_symbol_key) { :display_name }
    let(:hash_symbol_value) { "John Doe" }
    let(:hash_string_key) { "email" }
    let(:hash_string_value) { "john@example.com" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { user_data }
  end

  let(:user_data) do
    {
      "user_id" => "user-123",
      "type" => "user",
      "display_name" => "John Doe",
      "email" => "john@example.com",
      "avatar" => "https://example.com/avatar.png",
      "role" => "admin",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600
    }
  end

  subject(:user) { described_class.from_response(user_data) }

  describe ".from_response" do
    it "creates a user from hash data" do
      expect(user).to be_a(described_class)
      expect(user.user_id).to eq("user-123")
      expect(user.display_name).to eq("John Doe")
      expect(user.email).to eq("john@example.com")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = user.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:user_id]).to eq("user-123")
      expect(hash[:display_name]).to eq("John Doe")
    end
  end

  describe "#user_identifier" do
    it "returns user_id when id is not present" do
      expect(user.user_identifier).to eq("user-123")
    end

    it "returns id when present" do
      user_with_id = described_class.from_json({"id" => "u-456", "display_name" => "Test"}.to_json)
      expect(user_with_id.user_identifier).to eq("u-456")
    end

    it "prefers id over user_id" do
      user_with_both = described_class.from_json({"id" => "u-456", "user_id" => "user-789"}.to_json)
      expect(user_with_both.user_identifier).to eq("u-456")
    end
  end
end
