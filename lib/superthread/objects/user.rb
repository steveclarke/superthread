# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a Superthread user.
    #
    # @example
    #   user = client.users.me
    #   user.display_name    # => "John Doe"
    #   user.email           # => "john@example.com"
    #
    class User < Superthread::Object
      OBJECT_NAME = 'user'
      Superthread::Object.register_type(OBJECT_NAME, self)

      attr_reader :user_id, :type, :display_name, :email, :avatar,
                  :role, :time_created, :time_updated

      def initialize(data = {})
        super
        @user_id = @data[:user_id]
        @type = @data[:type]
        @display_name = @data[:display_name]
        @email = @data[:email]
        @avatar = @data[:avatar]
        @role = @data[:role]
        @time_created = @data[:time_created]
        @time_updated = @data[:time_updated]
      end

      # Alias for user_id for consistency with other objects.
      #
      # @return [String] User ID
      def id
        @user_id
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
