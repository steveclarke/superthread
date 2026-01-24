# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for workspace member operations.
    class Members < Base
      desc "list", "List workspace members"
      def list
        handle_error do
          members = client.users.members(workspace_id)
          output_list members, columns: %i[display_name email role]
        end
      end
    end
  end
end
