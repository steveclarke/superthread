# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread comment.
    #
    # Comments are discussion items attached to cards. They support threaded
    # replies through the parent_id and replies attributes.
    #
    # @example
    #   comment = client.comments.find(workspace_id, comment_id)
    #   comment.content      # => "This looks great!"
    #   comment.user_id      # => "u123"
    #   comment.replies      # => [#<Superthread::Models::Comment ...>]
    #   comment.reply?       # => false
    class Comment < Superthread::Model
      include Concerns::Presentable
      include Concerns::Timestampable

      presents_as(:content) { content.to_s.then { |c| (c.length > 50) ? "#{c[0..47]}..." : c } }

      # @!attribute [rw] id
      #   @return [String] unique comment identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] comment type
      attribute :type, Shale::Type::String

      # @!attribute [rw] content
      #   @return [String] HTML content of the comment
      attribute :content, Shale::Type::String

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who posted the comment
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] card_id
      #   @return [String] ID of the card this comment is on
      attribute :card_id, Shale::Type::String

      # @!attribute [rw] parent_id
      #   @return [String, nil] ID of the parent comment if this is a reply
      attribute :parent_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the comment was posted
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the comment was last edited
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] replies
      #   @return [Array<Comment>] threaded replies to this comment
      attribute :replies, Comment, collection: true

      timestamps :time_created, :time_updated

      # Check if this is a reply to another comment.
      #
      # @return [Boolean] True if this is a reply
      def reply?
        !!parent_id
      end
    end
  end
end
