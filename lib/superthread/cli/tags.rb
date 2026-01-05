# frozen_string_literal: true

module Superthread
  module Cli
    class Tags < Base
      desc "create", "Create a new tag"
      option :name, type: :string, required: true, desc: "Tag name"
      option :color, type: :string, required: true, desc: "Tag color (hex)"
      option :space_id, type: :string, desc: "Space ID"
      def create
        output client.tags.create(
          workspace_id,
          name: options[:name],
          color: options[:color],
          space_id: options[:space_id]
        )
      end

      desc "update TAG_ID", "Update a tag"
      option :name, type: :string, desc: "New name"
      option :color, type: :string, desc: "New color (hex)"
      def update(tag_id)
        output client.tags.update(
          workspace_id,
          tag_id,
          **options.slice(:name, :color).transform_keys(&:to_sym)
        )
      end

      desc "delete TAG_ID", "Delete a tag"
      def delete(tag_id)
        output client.tags.delete(workspace_id, tag_id)
      end
    end
  end
end
