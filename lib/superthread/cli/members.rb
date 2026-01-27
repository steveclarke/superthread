# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for workspace member operations.
    class Members < Base
      desc "list", "List workspace members"
      # Lists all members of the current workspace.
      #
      # @return [void]
      def list
        handle_error do
          members = client.users.members(workspace_id)
          output_list members, columns: %i[id display_name email role], headers: {id: "USER_ID"}
        end
      end
    end
  end
end
