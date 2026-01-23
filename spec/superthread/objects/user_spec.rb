# frozen_string_literal: true

RSpec.describe Superthread::Objects::User do
  let(:user_data) do
    {
      user_id: "user-123",
      type: "user",
      display_name: "John Doe",
      email: "john@example.com",
      avatar: "https://example.com/avatar.png",
      role: "admin",
      time_created: 1705312200000,
      time_updated: 1705398600000
    }
  end

  subject(:user) { described_class.new(user_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(user.user_id).to eq("user-123")
      expect(user.type).to eq("user")
      expect(user.display_name).to eq("John Doe")
      expect(user.email).to eq("john@example.com")
      expect(user.avatar).to eq("https://example.com/avatar.png")
      expect(user.role).to eq("admin")
      expect(user.time_created).to eq(1705312200000)
      expect(user.time_updated).to eq(1705398600000)
    end
  end

  describe "#id" do
    it "returns user_id" do
      expect(user.id).to eq("user-123")
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(user.created_at).to be_a(Time)
      expect(user.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      user = described_class.new({})
      expect(user.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(user.updated_at).to be_a(Time)
      expect(user.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      user = described_class.new({})
      expect(user.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'user' type" do
      expect(Superthread::Object.object_types["user"]).to eq(described_class)
    end
  end
end
