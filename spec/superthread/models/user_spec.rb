# frozen_string_literal: true

RSpec.describe Superthread::Models::User do
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

  describe "#id" do
    it "returns user_id for consistency" do
      expect(user.id).to eq("user-123")
      expect(user.id).to eq(user.user_id)
    end
  end

  describe "time helpers" do
    it "converts time_created to Time" do
      expect(user.created_at).to be_a(Time)
      expect(user.created_at.year).to eq(2024)
    end

    it "converts time_updated to Time" do
      expect(user.updated_at).to be_a(Time)
    end

    it "returns nil for missing times" do
      user_without_times = described_class.from_response({"user_id" => "1"})
      expect(user_without_times.created_at).to be_nil
      expect(user_without_times.updated_at).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the display name" do
      expect(user.to_s).to eq("John Doe")
    end

    it "returns empty string when display_name is nil" do
      user_without_name = described_class.from_response({"user_id" => "1"})
      expect(user_without_name.to_s).to eq("")
    end
  end

  describe "hash-like access" do
    it "supports bracket access" do
      expect(user[:display_name]).to eq("John Doe")
      expect(user["email"]).to eq("john@example.com")
    end

    it "supports key? check" do
      expect(user.key?(:display_name)).to be true
      expect(user.key?(:nonexistent)).to be false
    end
  end

  describe "#==" do
    it "compares by attributes" do
      user2 = described_class.from_response(user_data)
      expect(user).to eq(user2)
    end

    it "returns false for different users" do
      user2 = described_class.from_response(user_data.merge("user_id" => "different"))
      expect(user).not_to eq(user2)
    end
  end
end
