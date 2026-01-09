# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for card (task/issue) operations.
    class Cards < Base
      # Creates a new card.
      # API: POST /:workspace/cards
      #
      # @param workspace_id [String] Workspace ID
      # @param params [Hash] Card creation parameters
      # @option params [String] :title Card title (required)
      # @option params [String] :list_id List ID (required)
      # @option params [String] :board_id Board ID (required unless sprint_id provided)
      # @option params [String] :sprint_id Sprint ID (required unless board_id provided)
      # @option params [String] :content Card content (HTML)
      # @option params [String] :project_id Project ID
      # @option params [Integer] :start_date Start date (Unix timestamp)
      # @option params [Integer] :due_date Due date (Unix timestamp)
      # @option params [Integer] :priority Priority level
      # @option params [Integer] :estimate Estimate
      # @option params [String] :parent_card_id Parent card ID
      # @option params [String] :epic_id Epic ID
      # @option params [String] :owner_id Owner user ID
      # @return [Superthread::Objects::Card] Created card
      def create(workspace_id, **params)
        unless params[:board_id] || params[:sprint_id]
          raise ArgumentError, 'Either board_id or sprint_id must be provided'
        end

        ws = safe_id('workspace_id', workspace_id)
        post_object("/#{ws}/cards", body: params,
                                    object_class: Objects::Card, unwrap_key: :card)
      end

      # Updates an existing card.
      # Note: Content cannot be updated via API (uses WebSocket collaboration).
      # API: PATCH /:workspace/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param params [Hash] Update parameters (only specified fields are updated)
      # @return [Superthread::Objects::Card] Updated card
      def update(workspace_id, card_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        patch_object("/#{ws}/cards/#{card}", body: compact_params(**params),
                                             object_class: Objects::Card, unwrap_key: :card)
      end

      # Gets a specific card with full details.
      # API: GET /:workspace/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @return [Superthread::Objects::Card] Card details
      def find(workspace_id, card_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        get_object("/#{ws}/cards/#{card}",
                   object_class: Objects::Card, unwrap_key: :card)
      end

      # Deletes a card.
      # API: DELETE /:workspace/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @return [Superthread::Object] Success response
      def destroy(workspace_id, card_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        http_delete("/#{ws}/cards/#{card}")
        success_response
      end

      # Duplicates a card.
      # API: POST /:workspace/cards/:card/copy
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID to duplicate
      # @param params [Hash] Optional destination parameters
      # @return [Superthread::Objects::Card] Duplicated card
      def duplicate(workspace_id, card_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        post_object("/#{ws}/cards/#{card}/copy", body: compact_params(**params),
                                                 object_class: Objects::Card, unwrap_key: :card)
      end

      # Gets cards assigned to a user.
      # API: POST /:workspace/views/preview
      #
      # @param workspace_id [String] Workspace ID
      # @param user_id [String] User ID
      # @param filters [Hash] Optional filters
      # @return [Superthread::Objects::Collection<Card>] List of assigned cards
      def assigned(workspace_id, user_id:, **filters)
        ws = safe_id('workspace_id', workspace_id)

        body = {
          type: 'card',
          card_filters: {
            include: { members: [user_id] }
          }
        }

        body[:card_filters][:is_archived] = filters[:archived] unless filters[:archived].nil?
        body[:card_filters][:include][:boards] = [filters[:board_id]] if filters[:board_id]
        body[:card_filters][:include][:lists] = [filters[:list_id]] if filters[:list_id]
        body[:card_filters][:include][:projects] = [filters[:project_id]] if filters[:project_id]

        post_collection("/#{ws}/views/preview", body: body,
                                                item_class: Objects::Card, items_key: :cards)
      end

      # Links two cards with a relationship.
      # API: POST /:workspace/cards/:card/linked_cards
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Source card ID
      # @param related_card_id [String] Card ID to link
      # @param relation_type [String] Type: blocks, blocked_by, related, duplicates
      # @return [Superthread::Object] Link result
      def add_related(workspace_id, card_id, related_card_id:, relation_type:)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)

        post_object("/#{ws}/cards/#{card}/linked_cards", body: {
                      card_id: related_card_id,
                      linked_card_type: relation_type
                    })
      end

      # Removes a card relationship.
      # API: DELETE /:workspace/cards/:card/linked_cards/:linked
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Source card ID
      # @param linked_card_id [String] Linked card ID to remove
      # @return [Superthread::Object] Success response
      def remove_related(workspace_id, card_id, linked_card_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        linked = safe_id('linked_card_id', linked_card_id)
        http_delete("/#{ws}/cards/#{card}/linked_cards/#{linked}")
        success_response
      end

      # Adds a member to a card.
      # API: POST /:workspace/cards/:card/members
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param user_id [String] User ID to add
      # @param role [String] Member role (default: "member")
      # @return [Superthread::Object] Result
      def add_member(workspace_id, card_id, user_id:, role: 'member')
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        post_object("/#{ws}/cards/#{card}/members", body: { user_id: user_id, role: role })
      end

      # Removes a member from a card.
      # API: DELETE /:workspace/cards/:card/members/:user
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param user_id [String] User ID to remove
      # @return [Superthread::Object] Success response
      def remove_member(workspace_id, card_id, user_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        user = safe_id('user_id', user_id)
        http_delete("/#{ws}/cards/#{card}/members/#{user}")
        success_response
      end

      # Creates a checklist on a card.
      # API: POST /:workspace/cards/:card/checklists
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param title [String] Checklist title
      # @return [Superthread::Objects::Checklist] Created checklist
      def create_checklist(workspace_id, card_id, title:)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        post_object("/#{ws}/cards/#{card}/checklists", body: { title: title },
                                                       object_class: Objects::Checklist)
      end

      # Adds an item to a checklist.
      # API: POST /:workspace/cards/:card/checklists/:checklist/items
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param title [String] Item title
      # @param checked [Boolean] Whether item is checked (default: false)
      # @return [Superthread::Objects::ChecklistItem] Created item
      def add_checklist_item(workspace_id, card_id, checklist_id, title:, checked: false)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        checklist = safe_id('checklist_id', checklist_id)

        post_object("/#{ws}/cards/#{card}/checklists/#{checklist}/items", body: {
                      title: title,
                      checklist_id: checklist_id,
                      checked: checked
                    }, object_class: Objects::ChecklistItem)
      end

      # Updates a checklist item.
      # API: PATCH /:workspace/cards/:card/checklists/:checklist/items/:item
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param item_id [String] Item ID
      # @param params [Hash] Update parameters (title, checked)
      # @return [Superthread::Objects::ChecklistItem] Updated item
      def update_checklist_item(workspace_id, card_id, checklist_id, item_id, **params)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        checklist = safe_id('checklist_id', checklist_id)
        item = safe_id('item_id', item_id)

        patch_object("/#{ws}/cards/#{card}/checklists/#{checklist}/items/#{item}",
                     body: compact_params(**params), object_class: Objects::ChecklistItem)
      end

      # Deletes a checklist item.
      # API: DELETE /:workspace/cards/:card/checklists/:checklist/items/:item
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param item_id [String] Item ID
      # @return [Superthread::Object] Success response
      def delete_checklist_item(workspace_id, card_id, checklist_id, item_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        checklist = safe_id('checklist_id', checklist_id)
        item = safe_id('item_id', item_id)

        http_delete("/#{ws}/cards/#{card}/checklists/#{checklist}/items/#{item}")
        success_response
      end

      # Updates a checklist title.
      # API: PATCH /:workspace/cards/:card/checklists/:checklist
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param title [String] New title
      # @return [Superthread::Objects::Checklist] Updated checklist
      def update_checklist(workspace_id, card_id, checklist_id, title:)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        checklist = safe_id('checklist_id', checklist_id)

        patch_object("/#{ws}/cards/#{card}/checklists/#{checklist}", body: { title: title },
                                                                     object_class: Objects::Checklist)
      end

      # Deletes a checklist.
      # API: DELETE /:workspace/cards/:card/checklists/:checklist
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @return [Superthread::Object] Success response
      def delete_checklist(workspace_id, card_id, checklist_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        checklist = safe_id('checklist_id', checklist_id)

        http_delete("/#{ws}/cards/#{card}/checklists/#{checklist}")
        success_response
      end

      # Gets available tags for a workspace.
      # API: GET /:workspace/tags
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Optional project ID to filter by
      # @param all [Boolean] Whether to get all tags
      # @return [Superthread::Objects::Collection<Tag>] List of tags
      def tags(workspace_id, project_id: nil, all: nil)
        ws = safe_id('workspace_id', workspace_id)
        params = compact_params(project_id: project_id, all: all)
        get_collection("/#{ws}/tags", params: params,
                                      item_class: Objects::Tag, items_key: :tags)
      end

      # Adds tags to a card.
      # API: POST /:workspace/cards/:card/tags
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param tag_ids [Array<String>, String] Tag ID(s) to add
      # @return [Superthread::Object] Result
      def add_tags(workspace_id, card_id, tag_ids:)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)

        body = tag_ids.is_a?(Array) ? { ids: tag_ids } : { id: tag_ids }
        post_object("/#{ws}/cards/#{card}/tags", body: body)
      end

      # Removes a tag from a card.
      # API: DELETE /:workspace/cards/:card/tags/:tag
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param tag_id [String] Tag ID to remove
      # @return [Superthread::Object] Success response
      def remove_tag(workspace_id, card_id, tag_id)
        ws = safe_id('workspace_id', workspace_id)
        card = safe_id('card_id', card_id)
        tag = safe_id('tag_id', tag_id)
        http_delete("/#{ws}/cards/#{card}/tags/#{tag}")
        success_response
      end
    end
  end
end
