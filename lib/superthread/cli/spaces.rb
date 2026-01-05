# frozen_string_literal: true

module Superthread
  module Cli
    class Spaces < Base
      desc "list", "List all spaces"
      def list
        output client.spaces.list(workspace_id)
      end

      desc "get SPACE_ID", "Get space details"
      def get(space_id)
        output client.spaces.find(workspace_id, space_id)
      end

      desc "create", "Create a new space"
      option :title, type: :string, required: true, desc: "Space title"
      option :description, type: :string, desc: "Space description"
      option :icon, type: :string, desc: "Space icon"
      def create
        output client.spaces.create(
          workspace_id,
          title: options[:title],
          description: options[:description],
          icon: options[:icon]
        )
      end

      desc "update SPACE_ID", "Update a space"
      option :title, type: :string, desc: "New title"
      option :description, type: :string, desc: "New description"
      option :icon, type: :string, desc: "New icon"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      def update(space_id)
        output client.spaces.update(
          workspace_id,
          space_id,
          **options.slice(:title, :description, :icon, :archived).transform_keys(&:to_sym)
        )
      end

      desc "delete SPACE_ID", "Delete a space"
      def delete(space_id)
        output client.spaces.destroy(workspace_id, space_id)
      end

      desc "add_member SPACE_ID USER_ID", "Add a member to a space"
      option :role, type: :string, desc: "Member role"
      def add_member(space_id, user_id)
        output client.spaces.add_member(workspace_id, space_id, user_id: user_id, role: options[:role])
      end

      desc "remove_member SPACE_ID MEMBER_ID", "Remove a member from a space"
      def remove_member(space_id, member_id)
        output client.spaces.remove_member(workspace_id, space_id, member_id)
      end
    end
  end
end
