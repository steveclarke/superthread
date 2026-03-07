# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing comments on Superthread cards and pages.
    #
    # Provides subcommands for creating, updating, and deleting comments.
    class Comments < Base
      desc "list", "List comments on a card"
      option :card, type: :string, required: true, aliases: "-c", desc: "Card ID"
      # List all comments on a specified card.
      #
      # @return [void]
      def list
        handle_error do
          comments = client.comments.list(workspace_id, card_id: options[:card])
          output_list comments, columns: %i[id user_id content time_created], headers: {id: "COMMENT_ID"}
        end
      end

      desc "get COMMENT_ID", "Get comment details"
      # Display detailed information about a specific comment.
      #
      # @param comment_id [String] the unique identifier of the comment to retrieve
      # @return [void]
      def get(comment_id)
        handle_error do
          comment = with_not_found("Comment not found: '#{comment_id}'.") do
            client.comments.find(workspace_id, comment_id)
          end
          output_item comment, fields: %i[id content user_id card_id time_created time_updated],
            labels: {id: "Comment ID"}
        end
      end

      desc "create", "Create a comment"
      option :content, type: :string, required: true, desc: "Comment content (HTML). Use {{@Name}} to mention users"
      option :card, type: :string, aliases: "-c", desc: "Parent card ID (required unless --page)"
      option :page, type: :string, aliases: "-p", desc: "Parent page ID (required unless --card)"
      # Create a new comment on a card or page.
      #
      # @return [void]
      def create
        opts = symbolized_options(:content)
        opts[:card_id] = options[:card] if options[:card]
        opts[:page_id] = options[:page] if options[:page]
        comment = client.comments.create(workspace_id, **opts)
        output_item comment, labels: {id: "Comment ID"}
      end

      desc "update COMMENT_ID", "Update a comment"
      option :content, type: :string, desc: "New content (HTML). Use {{@Name}} to mention users"
      option :status, type: :string, enum: %w[resolved open orphaned], desc: "Comment status"
      # Update an existing comment's content or status.
      #
      # @param comment_id [String] the unique identifier of the comment to update
      # @return [void]
      def update(comment_id)
        handle_error do
          comment = with_not_found("Comment not found: '#{comment_id}'.") do
            client.comments.update(workspace_id, comment_id, **symbolized_options(:content, :status))
          end
          output_item comment, labels: {id: "Comment ID"}
        end
      end

      desc "delete COMMENT_ID", "Delete a comment"
      # Permanently delete a comment after confirmation.
      #
      # @param comment_id [String] the unique identifier of the comment to delete
      # @return [void]
      def delete(comment_id)
        handle_error do
          comment = with_not_found("Comment not found: '#{comment_id}'.") do
            client.comments.find(workspace_id, comment_id)
          end
          preview = Formatter.truncate(Formatter.strip_html(comment.content), 50)
          confirming("Delete comment '#{preview}' (#{comment.id})?") do
            client.comments.destroy(workspace_id, comment.id)
            output_success "Comment #{comment.id} deleted"
          end
        end
      end
    end
  end
end
