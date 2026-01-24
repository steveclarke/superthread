# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread comment.
    #
    # @example
    #   comment = client.comments.find(workspace_id, comment_id)
    #   comment.content      # => "This looks great!"
    #   comment.user_id      # => "u123"
    #   comment.replies      # => [#<Superthread::Models::Comment ...>]
    #   comment.reply?       # => false
    #
    class Comment < Superthread::Model
      include Concerns::Timestampable

      attribute :id, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :content, Shale::Type::String
      attribute :user_id, Shale::Type::String
      attribute :card_id, Shale::Type::String
      attribute :parent_id, Shale::Type::String
      attribute :time_created, Shale::Type::Integer
      attribute :time_updated, Shale::Type::Integer

      # Nested replies (self-referential)
      attribute :replies, Comment, collection: true

      timestamps :time_created, :time_updated

      # Check if this is a reply to another comment.
      #
      # @return [Boolean] True if this is a reply
      def reply?
        !!parent_id
      end

      # String representation (truncated content).
      #
      # @return [String] Comment content preview
      def to_s
        return "" if content.nil?

        (content.length > 50) ? "#{content[0..47]}..." : content
      end
    end
  end
end
