# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Provides a DSL for defining resource resolvers that convert names to IDs.
      # Handles caching, ID detection, and error messages consistently.
      #
      # @example
      #   class Base < Thor
      #     include Concerns::Resolvable
      #
      #     resolver :space,
      #       loader: -> { client.spaces.list(workspace_id) },
      #       finder: ->(item, name) { item.title&.downcase == name.downcase },
      #       id_method: :id,
      #       not_found: "Space not found: '%s'. Use 'suth spaces list' to see available spaces."
      #
      #     resolver :user,
      #       loader: -> { client.users.members(workspace_id) },
      #       finder: ->(item, name) {
      #         item.display_name&.downcase == name.downcase ||
      #         item.email&.downcase == name.downcase
      #       },
      #       id_method: :user_id,
      #       not_found: "User not found: '%s'."
      #   end
      #
      #   # This creates:
      #   #   resolve_space(ref)  - returns ID or raises error
      #   #   find_space_by_name(name) - returns item or nil
      #
      module Resolvable
        extend ActiveSupport::Concern

        # Check if value looks like an ID (alphanumeric, reasonable length).
        #
        # @param value [String] The value to check
        # @return [Boolean] True if it looks like an ID
        def looks_like_id?(value)
          value.to_s.match?(/\A[a-zA-Z0-9_-]+\z/) && value.to_s.length <= 30
        end

        class_methods do
          # Define a resolver for a resource type.
          #
          # @param name [Symbol] The resource name (e.g., :space, :board)
          # @param loader [Proc] Lambda that loads all resources (called with instance context)
          # @param finder [Proc] Lambda that matches an item to a name (receives item, name)
          # @param id_method [Symbol] Method to call on item to get ID (default: :id)
          # @param not_found [String] Error message template with %s for the reference
          def resolver(name, loader:, finder:, id_method: :id, not_found: nil)
            cache_var = "@#{name}s_cache"
            not_found_msg = not_found || "#{name.to_s.capitalize} not found: '%s'."

            # Define find_*_by_name method
            define_method("find_#{name}_by_name") do |search_name|
              cache = instance_variable_get(cache_var)
              unless cache
                cache = instance_exec(&loader)
                instance_variable_set(cache_var, cache)
              end
              cache.find { |item| instance_exec(item, search_name, &finder) }
            end

            # Define resolve_* method
            define_method("resolve_#{name}") do |ref|
              return ref if ref.nil?
              return ref if looks_like_id?(ref)

              item = send("find_#{name}_by_name", ref)
              return item.send(id_method) if item

              raise Thor::Error, format(not_found_msg, ref)
            end
          end
        end
      end
    end
  end
end
