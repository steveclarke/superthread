# frozen_string_literal: true

module Superthread
  module Resources
    class Comments < Base
      # Creates a comment on a card or page.
      # API: POST /:workspace/comments
      #
      # @param workspace_id [String] Workspace ID
      # @param content [String] Comment content (HTML, max 102400 chars)
      # @param card_id [String] Card ID (required unless page_id provided)
      # @param page_id [String] Page ID (required unless card_id provided)
      # @param params [Hash] Optional parameters (schema, context)
      # @return [Hash] Created comment
      def create(workspace_id, content:, card_id: nil, page_id: nil, **params)
        ws = safe_id("workspace_id", workspace_id)
        body = build_params(content: content, card_id: card_id, page_id: page_id, **params)
        post("/#{ws}/comments", body: body)
      end

      # Gets a specific comment.
      # API: GET /:workspace/comments/:comment
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @return [Hash] Comment details
      def get(workspace_id, comment_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        get("/#{ws}/comments/#{comment}")
      end

      # Updates a comment.
      # API: PATCH /:workspace/comments/:comment
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @param params [Hash] Update parameters (content, status, context, schema)
      # @return [Hash] Updated comment
      def update(workspace_id, comment_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        patch("/#{ws}/comments/#{comment}", body: build_params(**params))
      end

      # Deletes a comment.
      # API: DELETE /:workspace/comments/:comment
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @return [Hash] Success response
      def delete(workspace_id, comment_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        delete("/#{ws}/comments/#{comment}")
      end

      # Replies to a comment.
      # API: POST /:workspace/comments/:comment/comments
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Parent comment ID
      # @param content [String] Reply content
      # @param params [Hash] Optional parameters (schema)
      # @return [Hash] Created reply
      def reply(workspace_id, comment_id, content:, **params)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        body = build_params(content: content, **params)
        post("/#{ws}/comments/#{comment}/comments", body: body)
      end

      # Gets replies to a comment.
      # API: GET /:workspace/comments/:comment/comments
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Comment ID
      # @return [Hash] List of replies
      def replies(workspace_id, comment_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        get("/#{ws}/comments/#{comment}/comments")
      end

      # Updates a reply.
      # API: PATCH /:workspace/comments/:comment/comments/:reply
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Parent comment ID
      # @param reply_id [String] Reply ID
      # @param params [Hash] Update parameters
      # @return [Hash] Updated reply
      def update_reply(workspace_id, comment_id, reply_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        reply = safe_id("reply_id", reply_id)
        patch("/#{ws}/comments/#{comment}/comments/#{reply}", body: build_params(**params))
      end

      # Deletes a reply.
      # API: DELETE /:workspace/comments/:comment/comments/:reply
      #
      # @param workspace_id [String] Workspace ID
      # @param comment_id [String] Parent comment ID
      # @param reply_id [String] Reply ID
      # @return [Hash] Success response
      def delete_reply(workspace_id, comment_id, reply_id)
        ws = safe_id("workspace_id", workspace_id)
        comment = safe_id("comment_id", comment_id)
        reply = safe_id("reply_id", reply_id)
        delete("/#{ws}/comments/#{comment}/comments/#{reply}")
      end
    end
  end
end
