# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing comments on Superthread cards and pages.
    #
    # Provides subcommands for creating, updating, deleting comments,
    # as well as managing threaded replies.
    class Comments < Base
      # Kebab-case aliases for commands
      map "update-reply" => :update_reply,
        "delete-reply" => :delete_reply

      desc "get COMMENT_ID", "Get comment details"
      option :open, type: :boolean, aliases: "-o", desc: "Open in web browser"
      # Display detailed information about a specific comment.
      #
      # @param comment_id [String] the unique identifier of the comment to retrieve
      # @return [void]
      def get(comment_id)
        handle_error do
          comment = client.comments.find(workspace_id, comment_id)
          output_item comment, fields: %i[id content user_id card_id time_created time_updated]

          # For comments, open the parent card if available
          if options[:open]
            if comment.card_id
              open_in_browser(:card, comment.card_id)
            else
              Ui.warning "Cannot open comment in browser (no associated card)"
            end
          end
        end
      end

      desc "create", "Create a comment"
      option :content, type: :string, required: true, desc: "Comment content (HTML)"
      option :card, type: :string, aliases: "-c", desc: "Card ID (required unless --page)"
      option :page, type: :string, aliases: "-p", desc: "Page ID (required unless --card)"
      # Create a new comment on a card or page.
      #
      # @return [void]
      def create
        opts = symbolized_options(:content)
        opts[:card_id] = options[:card] if options[:card]
        opts[:page_id] = options[:page] if options[:page]
        comment = client.comments.create(workspace_id, **opts)
        output_item comment
      end

      desc "update COMMENT_ID", "Update a comment"
      option :content, type: :string, desc: "New content"
      option :status, type: :string, enum: %w[resolved open orphaned], desc: "Comment status"
      # Update an existing comment's content or status.
      #
      # @param comment_id [String] the unique identifier of the comment to update
      # @return [void]
      def update(comment_id)
        comment = client.comments.update(workspace_id, comment_id, **symbolized_options(:content, :status))
        output_item comment
      end

      desc "delete COMMENT_ID", "Delete a comment"
      # Permanently delete a comment after confirmation.
      #
      # @param comment_id [String] the unique identifier of the comment to delete
      # @return [void]
      def delete(comment_id)
        handle_error do
          comment = client.comments.find(workspace_id, comment_id)
          preview = truncate_content(comment.content)
          confirming("Delete comment '#{preview}' (#{comment.id})?") do
            client.comments.destroy(workspace_id, comment.id)
            output_success "Comment #{comment.id} deleted"
          end
        end
      end

      desc "reply COMMENT_ID", "Reply to a comment"
      option :content, type: :string, required: true, desc: "Reply content"
      # Add a threaded reply to an existing comment.
      #
      # @param comment_id [String] the unique identifier of the parent comment
      # @return [void]
      def reply(comment_id)
        comment = client.comments.reply(workspace_id, comment_id, content: options[:content])
        output_item comment
      end

      desc "replies COMMENT_ID", "Get replies to a comment"
      # List all replies to a specific comment.
      #
      # @param comment_id [String] the unique identifier of the parent comment
      # @return [void]
      def replies(comment_id)
        comments = client.comments.replies(workspace_id, comment_id)
        output_list comments, columns: %i[id content user_id time_created]
      end

      desc "update-reply", "Update a reply"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      option :reply, type: :string, required: true, desc: "Reply ID"
      option :content, type: :string, desc: "New content"
      option :status, type: :string, enum: %w[resolved open orphaned], desc: "Status"
      # Update an existing reply's content or status.
      #
      # @return [void]
      def update_reply
        comment = client.comments.update_reply(workspace_id, options[:comment], options[:reply],
                                               **symbolized_options(:content, :status))
        output_item comment
      end

      desc "delete-reply", "Delete a reply"
      option :comment, type: :string, required: true, desc: "Parent comment ID"
      option :reply, type: :string, required: true, desc: "Reply ID"
      # Permanently delete a reply after confirmation.
      #
      # @return [void]
      def delete_reply
        handle_error do
          reply = client.comments.find(workspace_id, options[:reply])
          preview = truncate_content(reply.content)
          confirming("Delete reply '#{preview}' (#{reply.id})?") do
            client.comments.delete_reply(workspace_id, options[:comment], reply.id)
            output_success "Reply #{reply.id} deleted"
          end
        end
      end
    end
  end
end
