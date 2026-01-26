# frozen_string_literal: true

module Superthread
  module Models
    # Represents a Superthread space.
    #
    # Spaces are organizational containers within a workspace that group
    # related projects, pages, and other content. They can have dedicated
    # members with specific access.
    #
    # @example
    #   space = client.spaces.find(workspace_id, space_id)
    #   space.title       # => "Engineering"
    #   space.members     # => [#<Superthread::Models::Member ...>]
    #   space.archived?   # => false
    class Space < Superthread::Model
      include Concerns::Archivable
      include Concerns::Presentable
      include Concerns::Timestampable

      # @!attribute [rw] id
      #   @return [String] unique space identifier
      attribute :id, Shale::Type::String

      # @!attribute [rw] type
      #   @return [String] space type
      attribute :type, Shale::Type::String

      # @!attribute [rw] team_id
      #   @return [String] ID of the team/workspace this space belongs to
      attribute :team_id, Shale::Type::String

      # @!attribute [rw] title
      #   @return [String] display title of the space
      attribute :title, Shale::Type::String

      # @!attribute [rw] description
      #   @return [String] space description or purpose
      attribute :description, Shale::Type::String

      # @!attribute [rw] icon
      #   @return [Object] emoji or icon data for the space
      attribute :icon, Shale::Type::Value

      # @!attribute [rw] user_id
      #   @return [String] ID of the user who created the space
      attribute :user_id, Shale::Type::String

      # @!attribute [rw] time_created
      #   @return [Integer] Unix timestamp when the space was created
      attribute :time_created, Shale::Type::Integer

      # @!attribute [rw] time_updated
      #   @return [Integer] Unix timestamp when the space was last updated
      attribute :time_updated, Shale::Type::Integer

      # @!attribute [rw] members
      #   @return [Array<Member>] users with access to this space
      attribute :members, Member, collection: true

      # @!attribute [rw] archived
      #   @return [Hash{String => Object}, nil] archive metadata with user_id and time_archived
      attribute :archived, Shale::Type::Value

      timestamps :time_created, :time_updated
    end
  end
end
