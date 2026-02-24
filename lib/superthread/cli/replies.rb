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
          output_list replies, columns: %i[id content user_id time_created], headers: {id: "REPLY_ID"}
        end
      end

      desc "get REPLY_ID", "Get reply details"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      # Display detailed information about a specific reply.
      #
      # @param reply_id [String] the unique identifier of the reply
      # @return [void]
      def get(reply_id)
        handle_error do
          begin
            reply = client.comments.find_reply(workspace_id, options[:comment], reply_id)
          rescue Superthread::NotFoundError
            raise Thor::Error, "Reply not found: '#{reply_id}' on comment '#{options[:comment]}'."
          end
          output_item reply, fields: %i[id content user_id card_id time_created time_updated], labels: {
            id: "Reply ID",
            user_id: "User ID",
            card_id: "Card ID",
            time_created: "Time Created",
            time_updated: "Time Updated"
          }
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
          output_item reply, labels: {id: "Reply ID"}
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
          output_item reply, labels: {id: "Reply ID"}
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
          reply = client.comments.find_reply(workspace_id, options[:comment], reply_id)
          preview = Formatter.truncate(Formatter.strip_html(reply.content), 50)
          confirming("Delete reply '#{preview}' (#{reply_id})?") do
            client.comments.delete_reply(workspace_id, options[:comment], reply_id)
            output_success "Reply #{reply_id} deleted"
          end
        end
      end
    end
  end
end
