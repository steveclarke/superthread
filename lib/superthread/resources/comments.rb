# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for comment operations.
    class Comments < Base
      # Creates a comment on a card or page.
      # API: POST /:workspace/comments
      #
      # @param workspace_id [String] Workspace ID
      # @param content [String] Comment content (HTML, max 102400 chars)
      # @param card_id [String] Card ID (required unless page_id provided)
      # @param page_id [String] Page ID (required unless card_id provided)
      # @param params [Hash] Optional parameters (schema, context)
      # @return [Superthread::Objects::Comment] Created comment
      def create(workspace_id, content:, card_id: nil, page_id: nil, **params)
        ws = safe_id('workspace_id', workspace_id)
        body = compact_params(content: content, card_id: card_id, page_id: page_id, **params)
        post_object("/#{ws}/comments", body: body,
                                       object_class: Objects::Comment, unwrap_key: :comment)
      end

      # Gets a specific comment.
      # API: GET /:workspace/comments/:comment
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @return [Superthread::Objects::Comment] Comment details
      def find(workspace_id, comment_id)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        get_object("/#{ws}/comments/#{comment}",
                   object_class: Objects::Comment, unwrap_key: :comment)
      end

      # Updates a comment.
      # API: PATCH /:workspace/comments/:comment
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @param params [Hash] Update parameters (content, status, context, schema)
      # @return [Superthread::Objects::Comment] Updated comment
      def update(workspace_id, comment_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        patch_object("/#{ws}/comments/#{comment}", body: compact_params(**params),
                                                   object_class: Objects::Comment, unwrap_key: :comment)
      end

      # Deletes a comment.
      # API: DELETE /:workspace/comments/:comment
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, comment_id)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        http_delete("/#{ws}/comments/#{comment}")
        success_response
      end

      # Replies to a comment.
      # API: POST /:workspace/comments/:comment/comments
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Parent comment ID
      # @param content [String] Reply content
      # @param params [Hash] Optional parameters (schema)
      # @return [Superthread::Objects::Comment] Created reply
      def reply(workspace_id, comment_id, content:, **params)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        body = compact_params(content: content, **params)
        post_object("/#{ws}/comments/#{comment}/comments", body: body,
                                                           object_class: Objects::Comment, unwrap_key: :comment)
      end

      # Gets replies to a comment.
      # API: GET /:workspace/comments/:comment/comments
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @return [Superthread::Objects::Collection<Comment>] List of replies
      def replies(workspace_id, comment_id)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        get_collection("/#{ws}/comments/#{comment}/comments",
                       item_class: Objects::Comment, items_key: :comments)
      end

      # Updates a reply.
      # API: PATCH /:workspace/comments/:comment/comments/:reply
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Parent comment ID
      # @param reply_id [String] Reply ID
      # @param params [Hash] Update parameters
      # @return [Superthread::Objects::Comment] Updated reply
      def update_reply(workspace_id, comment_id, reply_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        reply = safe_id('reply_id', reply_id)
        patch_object("/#{ws}/comments/#{comment}/comments/#{reply}", body: compact_params(**params),
                                                                     object_class: Objects::Comment, unwrap_key: :comment)
      end

      # Deletes a reply.
      # API: DELETE /:workspace/comments/:comment/comments/:reply
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Parent comment ID
      # @param reply_id [String] Reply ID
      # @return [Superthread::Object] Success response
      def delete_reply(workspace_id, comment_id, reply_id)
        ws = safe_id('workspace_id', workspace_id)
        comment = safe_id('comment_id', comment_id)
        reply = safe_id('reply_id', reply_id)
        http_delete("/#{ws}/comments/#{comment}/comments/#{reply}")
        success_response
      end
    end
  end
end
