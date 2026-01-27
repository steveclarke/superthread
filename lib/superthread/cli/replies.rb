# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing comment replies.
    #
    # Replies are threaded responses to comments on cards and pages.
    # This class provides commands to list, create, update, and delete replies.
    class Replies < Base
      desc "list", "List all replies to a comment"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      # List all replies to a specified comment.
      #
      # @return [void]
      def list
        handle_error do
          replies = client.comments.replies(workspace_id, options[:comment])
          output_list replies, columns: %i[id content user_id time_created]
        end
      end

      desc "get REPLY_ID", "Get reply details"
      # Display detailed information about a specific reply.
      #
      # @param reply_id [String] the unique identifier of the reply
      # @return [void]
      def get(reply_id)
        handle_error do
          reply = client.comments.find(workspace_id, reply_id)
          output_item reply, fields: %i[id content user_id card_id time_created time_updated]
        end
      end

      desc "create", "Reply to a comment"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      option :content, type: :string, required: true, desc: "Reply content"
      # Add a threaded reply to an existing comment.
      #
      # @return [void]
      def create
        handle_error do
          reply = client.comments.reply(workspace_id, options[:comment], content: options[:content])
          output_item reply
        end
      end

      desc "update REPLY_ID", "Update a reply"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      option :content, type: :string, desc: "New content"
      option :status, type: :string, enum: %w[resolved open orphaned], desc: "Status"
      # Update an existing reply's content or status.
      #
      # @param reply_id [String] the unique identifier of the reply
      # @return [void]
      def update(reply_id)
        handle_error do
          reply = client.comments.update_reply(
            workspace_id, options[:comment], reply_id,
            **symbolized_options(:content, :status)
          )
          output_item reply
        end
      end

      desc "delete REPLY_ID", "Delete a reply"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      # Permanently delete a reply after confirmation.
      #
      # @param reply_id [String] the unique identifier of the reply
      # @return [void]
      def delete(reply_id)
        handle_error do
          reply = client.comments.find(workspace_id, reply_id)
          preview = truncate_content(reply.content)
          confirming("Delete reply '#{preview}' (#{reply_id})?") do
            client.comments.delete_reply(workspace_id, options[:comment], reply_id)
            output_success "Reply #{reply_id} deleted"
          end
        end
      end
    end
  end
end
