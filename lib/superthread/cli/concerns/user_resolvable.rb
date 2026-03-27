# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Resolves user references (ID, name, or email) to user identifiers.
      #
      # User resolution matches against display_name or email and returns
      # the user_identifier (not the standard id field).
      module UserResolvable
        extend ActiveSupport::Concern

        private

        # Resolve a user reference (ID, name, or email) to their user identifier.
        #
        # @param ref [String, nil] the user ID, display name, or email to resolve
        # @return [String, nil] the resolved user identifier
        # @raise [Thor::Error] if name/email is provided but not found
        def resolve_user(ref)
          return ref if ref.nil?

          return resolve_me if ref.downcase == "me"

          return ref if looks_like_id?(ref)

          user = find_user_by_name(ref)
          return user.user_identifier if user

          raise Thor::Error, "User not found: '#{ref}'. Use 'suth members list' to see available users."
        end

        # Resolve 'me' to the current user's identifier (cached).
        #
        # @return [String] the current user's identifier
        def resolve_me
          @me_cache ||= client.users.me.user_identifier
        end

        # Get cached workspace members list.
        #
        # @return [Array<Superthread::Models::User>] all workspace members
        def workspace_users
          @users_cache ||= client.users.members(workspace_id)
        end

        # Find a user by display name or email from the cached member list.
        #
        # @param name [String] the display name or email to search for (case-insensitive)
        # @return [Superthread::Models::User, nil] the user object or nil if not found
        def find_user_by_name(name)
          workspace_users.find do |u|
            u.display_name&.downcase == name.downcase ||
              u.email&.downcase == name.downcase
          end
        end
      end
    end
  end
end
