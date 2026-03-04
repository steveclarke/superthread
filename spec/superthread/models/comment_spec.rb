# frozen_string_literal: true

RSpec.describe Superthread::Models::Comment do
  it_behaves_like "presentable with block" do
    let(:model_class) { described_class }
    let(:test_data) { {"content" => "Short content"} }
    let(:expected_output) { "Short content" }
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
    let(:hash_symbol_key) { :content }
    let(:hash_symbol_value) { "This looks great! Nice work on the implementation." }
    let(:hash_string_key) { "user_id" }
    let(:hash_string_value) { "user-456" }
  end

  it_behaves_like "equatable" do
    let(:model_class) { described_class }
    let(:model_data) { comment_data }
  end

  let(:comment_data) do
    {
      "id" => "comment-123",
      "type" => "comment",
      "content" => "This looks great! Nice work on the implementation.",
      "user_id" => "user-456",
      "card_id" => "card-789",
      "time_created" => 1_705_312_200,
      "time_updated" => 1_705_398_600,
      "replies" => [
        {
          "id" => "reply-1",
          "content" => "Thanks!",
          "user_id" => "user-001",
          "parent_id" => "comment-123",
          "time_created" => 1_705_398_600
        }
      ]
    }
  end

  subject(:comment) { described_class.from_response(comment_data) }

  describe ".from_response" do
    it "creates a comment from hash data" do
      expect(comment).to be_a(described_class)
      expect(comment.id).to eq("comment-123")
      expect(comment.content).to eq("This looks great! Nice work on the implementation.")
    end
  end

  describe "#to_h" do
    it "returns a hash with symbol keys" do
      hash = comment.to_h
      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq("comment-123")
      expect(hash[:content]).to eq("This looks great! Nice work on the implementation.")
    end
  end

  describe "#reply?" do
    it "returns false for top-level comments" do
      expect(comment.reply?).to be false
    end

    it "returns true for replies" do
      reply = comment.replies.first
      expect(reply.reply?).to be true
    end
  end

  describe "nested replies" do
    it "parses replies as Comment objects" do
      expect(comment.replies).to be_an(Array)
      expect(comment.replies.length).to eq(1)
      expect(comment.replies.first).to be_a(described_class)
    end

    it "preserves reply data" do
      reply = comment.replies.first
      expect(reply.id).to eq("reply-1")
      expect(reply.content).to eq("Thanks!")
      expect(reply.parent_id).to eq("comment-123")
    end
  end

  describe "#to_s edge cases" do
    it "truncates long content" do
      long_content = "This is a very long comment that exceeds fifty characters and should be truncated"
      long_comment = described_class.from_response({"id" => "1", "content" => long_content})
      expect(long_comment.to_s.length).to eq(51) # 48 chars + "..."
      expect(long_comment.to_s).to end_with("...")
      expect(long_comment.to_s).to eq("This is a very long comment that exceeds fifty c...")
    end

    it "returns empty string when content is nil" do
      comment_without_content = described_class.from_response({"id" => "1"})
      expect(comment_without_content.to_s).to eq("")
    end
  end
end
