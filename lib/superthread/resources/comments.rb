# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for comment operations.
    #
    # Provides methods for creating, updating, and managing comments
    # on cards and pages, including threaded replies.
    class Comments < Base
      # Lists comments on a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier to list comments for
      # @return [Superthread::Objects::Collection<Superthread::Models::Comment>] the card's comments
      def list(workspace_id, card_id:)
        ws = safe_id("workspace_id", workspace_id)
        params = compact_params(card_id: card_id)
        get_collection("/#{ws}/comments", params: params,
          item_class: Models::Comment, items_key: :comments)
      end

      # Creates a comment on a card or page.
      #
      # @param workspace_id [String] the workspace identifier
      # @param content [String] the comment content as HTML (max 102400 chars)
      # @param card_id [String, nil] the card identifier (required unless page_id provided)
      # @param page_id [String, nil] the page identifier (required unless card_id provided)
      # @param params [Hash{Symbol => Object}] optional comment parameters
      # @option params [Hash{Symbol => Object}] :schema the content schema for structured content
      # @option params [Hash{Symbol => Object}] :context additional context metadata
      # @return [Superthread::Models::Comment] the created comment
      def create(workspace_id, content:, card_id: nil, page_id: nil, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = compact_params(content: content, card_id: card_id, page_id: page_id, **params)
        post_object("/#{ws}/comments", body: body,
          object_class: Models::Comment, unwrap_key: :comment)
      end

      # Gets a specific comment.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the comment identifier
      # @return [Superthread::Models::Comment] the comment with all attributes
      def find(workspace_id, comment_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        get_object("/#{ws}/comments/#{comment}",
          object_class: Models::Comment, unwrap_key: :comment)
      end

      # Updates a comment's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the comment identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :content the new comment content as HTML
      # @option params [String] :status the new comment status
      # @option params [Hash{Symbol => Object}] :context updated context metadata
      # @option params [Hash{Symbol => Object}] :schema updated content schema
      # @return [Superthread::Models::Comment] the updated comment
      def update(workspace_id, comment_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        patch_object("/#{ws}/comments/#{comment}", body: compact_params(**params),
          object_class: Models::Comment, unwrap_key: :comment)
      end

      # Deletes a comment permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the comment identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, comment_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        http_delete("/#{ws}/comments/#{comment}")
        success_response
      end

      # Replies to a comment, creating a threaded response.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the parent comment identifier
      # @param content [String] the reply content as HTML
      # @param params [Hash{Symbol => Object}] optional reply parameters
      # @option params [Hash{Symbol => Object}] :schema the content schema for structured content
      # @return [Superthread::Models::Comment] the created reply
      def reply(workspace_id, comment_id, content:, **params)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        body = compact_params(content: content, **params)
        post_object("/#{ws}/comments/#{comment}/children", body: body,
          object_class: Models::Comment, unwrap_key: :comment)
      end

      # Gets replies to a comment.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the parent comment identifier
      # @return [Superthread::Objects::Collection<Superthread::Models::Comment>] the threaded replies
      def replies(workspace_id, comment_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        get_collection("/#{ws}/comments/#{comment}/children",
          item_class: Models::Comment, items_key: :child_comments)
      end

      # Updates a reply's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the parent comment identifier
      # @param reply_id [String] the reply identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :content the new reply content as HTML
      # @option params [String] :status the new reply status
      # @return [Superthread::Models::Comment] the updated reply
      def update_reply(workspace_id, comment_id, reply_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        reply = safe_id("reply_id", reply_id)
        patch_object("/#{ws}/comments/#{comment}/children/#{reply}", body: compact_params(**params),
          object_class: Models::Comment, unwrap_key: :comment)
      end

      # Deletes a reply permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param comment_id [String] the parent comment identifier
      # @param reply_id [String] the reply identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def delete_reply(workspace_id, comment_id, reply_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        reply = safe_id("reply_id", reply_id)
        http_delete("/#{ws}/comments/#{comment}/children/#{reply}")
        success_response
      end
    end
  end
end
