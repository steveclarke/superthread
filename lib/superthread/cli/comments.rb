# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for comment operations.
    class Comments < Base
      desc 'get COMMENT_ID', 'Get comment details'
      def get(comment_id)
        comment = client.comments.find(workspace_id, comment_id)
        output_item comment, fields: %i[id content user_id card_id time_created time_updated]
      end

      desc 'create', 'Create a comment'
      option :content, type: :string, required: true, desc: 'Comment content (HTML)'
      option :card_id, type: :string, desc: 'Card ID (required unless page_id)'
      option :page_id, type: :string, desc: 'Page ID (required unless card_id)'
      def create
        comment = client.comments.create(workspace_id, **symbolized_options(:content, :card_id, :page_id))
        output_item comment
      end

      desc 'update COMMENT_ID', 'Update a comment'
      option :content, type: :string, desc: 'New content'
      option :status, type: :string, enum: %w[resolved open orphaned], desc: 'Comment status'
      def update(comment_id)
        comment = client.comments.update(workspace_id, comment_id, **symbolized_options(:content, :status))
        output_item comment
      end

      desc 'delete COMMENT_ID', 'Delete a comment'
      def delete(comment_id)
        client.comments.destroy(workspace_id, comment_id)
        output_success "Comment #{comment_id} deleted"
      end

      desc 'reply COMMENT_ID', 'Reply to a comment'
      option :content, type: :string, required: true, desc: 'Reply content'
      def reply(comment_id)
        comment = client.comments.reply(workspace_id, comment_id, content: options[:content])
        output_item comment
      end

      desc 'replies COMMENT_ID', 'Get replies to a comment'
      def replies(comment_id)
        comments = client.comments.replies(workspace_id, comment_id)
        output_list comments, columns: %i[id content user_id time_created]
      end

      desc 'update_reply COMMENT_ID REPLY_ID', 'Update a reply'
      option :content, type: :string, desc: 'New content'
      option :status, type: :string, enum: %w[resolved open orphaned], desc: 'Status'
      def update_reply(comment_id, reply_id)
        comment = client.comments.update_reply(workspace_id, comment_id, reply_id,
                                               **symbolized_options(:content, :status))
        output_item comment
      end

      desc 'delete_reply COMMENT_ID REPLY_ID', 'Delete a reply'
      def delete_reply(comment_id, reply_id)
        client.comments.delete_reply(workspace_id, comment_id, reply_id)
        output_success "Reply #{reply_id} deleted"
      end
    end
  end
end
