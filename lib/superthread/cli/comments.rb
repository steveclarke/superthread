# frozen_string_literal: true

module Superthread
  module Cli
    class Comments < Base
      desc "get COMMENT_ID", "Get comment details"
      def get(comment_id)
        output client.comments.get(workspace_id, comment_id)
      end

      desc "create", "Create a comment"
      option :content, type: :string, required: true, desc: "Comment content (HTML)"
      option :card_id, type: :string, desc: "Card ID (required unless page_id)"
      option :page_id, type: :string, desc: "Page ID (required unless card_id)"
      def create
        output client.comments.create(
          workspace_id,
          content: options[:content],
          card_id: options[:card_id],
          page_id: options[:page_id]
        )
      end

      desc "update COMMENT_ID", "Update a comment"
      option :content, type: :string, desc: "New content"
      option :status, type: :string, enum: %w[resolved open orphaned], desc: "Comment status"
      def update(comment_id)
        output client.comments.update(
          workspace_id,
          comment_id,
          **options.slice(:content, :status).transform_keys(&:to_sym)
        )
      end

      desc "delete COMMENT_ID", "Delete a comment"
      def delete(comment_id)
        output client.comments.delete(workspace_id, comment_id)
      end

      desc "reply COMMENT_ID", "Reply to a comment"
      option :content, type: :string, required: true, desc: "Reply content"
      def reply(comment_id)
        output client.comments.reply(workspace_id, comment_id, content: options[:content])
      end

      desc "replies COMMENT_ID", "Get replies to a comment"
      def replies(comment_id)
        output client.comments.replies(workspace_id, comment_id)
      end

      desc "update_reply COMMENT_ID REPLY_ID", "Update a reply"
      option :content, type: :string, desc: "New content"
      option :status, type: :string, enum: %w[resolved open orphaned], desc: "Status"
      def update_reply(comment_id, reply_id)
        output client.comments.update_reply(
          workspace_id,
          comment_id,
          reply_id,
          **options.slice(:content, :status).transform_keys(&:to_sym)
        )
      end

      desc "delete_reply COMMENT_ID REPLY_ID", "Delete a reply"
      def delete_reply(comment_id, reply_id)
        output client.comments.delete_reply(workspace_id, comment_id, reply_id)
      end
    end
  end
end
