# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread comment.
    #
    # @example
    #   comment = client.comments.find(workspace_id, comment_id)
    #   comment.content      # => "This looks great!"
    #   comment.user_id      # => "u123"
    #   comment.replies      # => [#<Superthread::Objects::Comment ...>]
    #
    class Comment < Superthread::Object
      OBJECT_NAME = 'comment'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :id, :type, :content, :user_id, :card_id, :parent_id,
                  :time_created, :time_updated

      def initialize(data = {})
        super
        @id = @data[:id]
        @type = @data[:type]
        @content = @data[:content]
        @user_id = @data[:user_id]
        @card_id = @data[:card_id]
        @parent_id = @data[:parent_id]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Returns replies as Comment objects.
      #
      # @return [Array<Superthread::Objects::Comment>] Replies
      def replies
        @replies ||= (@data[:replies] || []).map { |r| Comment.new(r) }
      end

      # Check if this is a reply to another comment.
      #
      # @return [Boolean] True if this is a reply
      def reply?
        !!@parent_id
      end

      # Returns time_created as a Time object.
      #
      # @return [Time, nil] Created time
      def created_at
        @time_created && Time.at(@time_created / 1000.0)
      end

      # Returns time_updated as a Time object.
      #
      # @return [Time, nil] Updated time
      def updated_at
        @time_updated && Time.at(@time_updated / 1000.0)
      end
    end
  end
end
