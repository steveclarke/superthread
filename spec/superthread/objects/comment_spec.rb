# frozen_string_literal: true

RSpec.describe Superthread::Objects::Comment do
  let(:comment_data) do
    {
      id: "comment-123",
      type: "comment",
      content: "This looks great!",
      user_id: "user-1",
      card_id: "card-1",
      parent_id: nil,
      time_created: 1705312200000,
      time_updated: 1705398600000,
      replies: [
        {id: "comment-reply-1", content: "Thanks!", user_id: "user-2", parent_id: "comment-123"}
      ]
    }
  end

  subject(:comment) { described_class.new(comment_data) }

  describe "#initialize" do
    it "assigns all attributes" do
      expect(comment.id).to eq("comment-123")
      expect(comment.type).to eq("comment")
      expect(comment.content).to eq("This looks great!")
      expect(comment.user_id).to eq("user-1")
      expect(comment.card_id).to eq("card-1")
      expect(comment.parent_id).to be_nil
      expect(comment.time_created).to eq(1705312200000)
      expect(comment.time_updated).to eq(1705398600000)
    end
  end

  describe "#replies" do
    it "returns Comment objects" do
      replies = comment.replies
      expect(replies).to be_an(Array)
      expect(replies.length).to eq(1)
      expect(replies.first).to be_a(described_class)
      expect(replies.first.content).to eq("Thanks!")
    end

    it "returns empty array when no replies" do
      comment = described_class.new({})
      expect(comment.replies).to eq([])
    end

    it "memoizes the result" do
      replies1 = comment.replies
      replies2 = comment.replies
      expect(replies1).to equal(replies2)
    end
  end

  describe "#reply?" do
    it "returns true when has parent_id" do
      comment = described_class.new(parent_id: "comment-123")
      expect(comment.reply?).to be true
    end

    it "returns false when no parent_id" do
      expect(comment.reply?).to be false
    end

    it "returns false when parent_id is nil" do
      comment = described_class.new(parent_id: nil)
      expect(comment.reply?).to be false
    end
  end

  describe "#created_at" do
    it "converts time_created to Time" do
      expect(comment.created_at).to be_a(Time)
      expect(comment.created_at.year).to eq(2024)
    end

    it "returns nil when time_created is nil" do
      comment = described_class.new({})
      expect(comment.created_at).to be_nil
    end
  end

  describe "#updated_at" do
    it "converts time_updated to Time" do
      expect(comment.updated_at).to be_a(Time)
      expect(comment.updated_at.year).to eq(2024)
    end

    it "returns nil when time_updated is nil" do
      comment = described_class.new({})
      expect(comment.updated_at).to be_nil
    end
  end

  describe "type registration" do
    it "is registered as 'comment' type" do
      expect(Superthread::Object.object_types["comment"]).to eq(described_class)
    end
  end
end
