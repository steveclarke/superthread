# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for tag operations.
    class Tags < Base
      desc 'create', 'Create a new tag'
      option :name, type: :string, required: true, desc: 'Tag name'
      option :color, type: :string, required: true, desc: 'Tag color (hex)'
      option :space_id, type: :string, desc: 'Space ID'
      def create
        tag = client.tags.create(workspace_id, **symbolized_options(:name, :color, :space_id))
        output_item tag, fields: %i[id name color]
      end

      desc 'update TAG_ID', 'Update a tag'
      option :name, type: :string, desc: 'New name'
      option :color, type: :string, desc: 'New color (hex)'
      def update(tag_id)
        tag = client.tags.update(workspace_id, tag_id, **symbolized_options(:name, :color))
        output_item tag
      end

      desc 'delete TAG_ID', 'Delete a tag'
      def delete(tag_id)
        client.tags.destroy(workspace_id, tag_id)
        output_success "Tag #{tag_id} deleted"
      end
    end
  end
end
