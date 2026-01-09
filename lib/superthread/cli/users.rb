# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for user operations.
    class Users < Base
      desc 'me', 'Show current user account info'
      def me
        user = client.users.me
        output_item user, fields: %i[user_id display_name email role time_created]
      end

      desc 'members', 'List workspace members'
      def members
        users = client.users.members(workspace_id)
        output_list users, columns: %i[user_id display_name email role]
      end
    end
  end
end
