# frozen_string_literal: true

module Superthread
  module Cli
    class Users < Base
      desc "me", "Show current user account info"
      def me
        output client.users.me
      end

      desc "members", "List workspace members"
      def members
        output client.users.members(workspace_id)
      end
    end
  end
end
