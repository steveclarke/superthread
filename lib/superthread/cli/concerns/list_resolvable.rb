# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves list references (ID or name) to list IDs.
      #
      # List resolution is context-dependent: it searches within the current
      # board's lists or the current sprint's lists, depending on which
      # option is provided.
      module ListResolvable
        extend ActiveSupport::Concern

        private

        # Resolve a list reference (ID or name) to its ID.
        #
        # @param ref [String, nil] the list ID or name to resolve
        # @return [String, nil] the resolved list ID
        # @raise [Thor::Error] if name is provided but not found
        def resolve_list(ref)
          return ref if ref.nil?
          return ref if looks_like_id?(ref)

          list = find_list_by_name(ref)
          return list.id if list

          raise Thor::Error, "List not found: '#{ref}'. Specify --board or --sprint to search by list name."
        end

        # Find a list by name within the current board or sprint context.
        #
        # @param name [String] the list name to search for (case-insensitive)
        # @return [Superthread::Models::List, nil] the list object or nil if not found
        def find_list_by_name(name)
          lists = if options[:board]
            board = client.boards.find(workspace_id, board_id)
            board.lists
          elsif options[:sprint]
            sprint = client.sprints.find(workspace_id, sprint_id, space_id: space_id)
            sprint.lists
          end

          return nil unless lists

          lists.find { |l| l.title&.downcase == name.downcase }
        end
      end
    end
  end
end
