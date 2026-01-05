# frozen_string_literal: true

module Superthread
  module Resources
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
      # @return [Hash] Created card
      def create(workspace_id, **params)
        unless params[:board_id] || params[:sprint_id]
          raise ArgumentError, "Either board_id or sprint_id must be provided"
        end

        ws = safe_id("workspace_id", workspace_id)
        post("/#{ws}/cards", body: params)
      end

      # Updates an existing card.
      # Note: Content cannot be updated via API (uses WebSocket collaboration).
      # API: PATCH /:workspace/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param params [Hash] Update parameters (only specified fields are updated)
      # @return [Hash] Updated card
      def update(workspace_id, card_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        patch("/#{ws}/cards/#{card}", body: build_params(**params))
      end

      # Gets a specific card with full details.
      # API: GET /:workspace/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @return [Hash] Card details
      def get(workspace_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        get("/#{ws}/cards/#{card}")
      end

      # Deletes a card.
      # API: DELETE /:workspace/cards/:card
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @return [Hash] Success response
      def delete(workspace_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        delete("/#{ws}/cards/#{card}")
      end

      # Duplicates a card.
      # API: POST /:workspace/cards/:card/copy
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID to duplicate
      # @param params [Hash] Optional destination parameters
      # @return [Hash] Duplicated card
      def duplicate(workspace_id, card_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        post("/#{ws}/cards/#{card}/copy", body: build_params(**params))
      end

      # Gets cards assigned to a user.
      # API: POST /:workspace/views/preview
      #
      # @param workspace_id [String] Workspace ID
      # @param user_id [String] User ID
      # @param filters [Hash] Optional filters
      # @return [Hash] List of assigned cards
      def assigned(workspace_id, user_id:, **filters)
        ws = safe_id("workspace_id", workspace_id)

        body = {
          type: "card",
          card_filters: {
            include: { members: [user_id] }
          }
        }

        body[:card_filters][:is_archived] = filters[:archived] unless filters[:archived].nil?
        body[:card_filters][:include][:boards] = [filters[:board_id]] if filters[:board_id]
        body[:card_filters][:include][:lists] = [filters[:list_id]] if filters[:list_id]
        body[:card_filters][:include][:projects] = [filters[:project_id]] if filters[:project_id]

        post("/#{ws}/views/preview", body: body)
      end

      # Links two cards with a relationship.
      # API: POST /:workspace/cards/:card/linked_cards
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Source card ID
      # @param related_card_id [String] Card ID to link
      # @param relation_type [String] Type: blocks, blocked_by, related, duplicates
      # @return [Hash] Link result
      def add_related(workspace_id, card_id, related_card_id:, relation_type:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)

        post("/#{ws}/cards/#{card}/linked_cards", body: {
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
      # @return [Hash] Success response
      def remove_related(workspace_id, card_id, linked_card_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        linked = safe_id("linked_card_id", linked_card_id)
        delete("/#{ws}/cards/#{card}/linked_cards/#{linked}")
      end

      # Adds a member to a card.
      # API: POST /:workspace/cards/:card/members (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param user_id [String] User ID to add
      # @param role [String] Member role (default: "member")
      # @return [Hash] Result
      def add_member(workspace_id, card_id, user_id:, role: "member")
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        post("/#{ws}/cards/#{card}/members", body: { user_id: user_id, role: role })
      end

      # Removes a member from a card.
      # API: DELETE /:workspace/cards/:card/members/:user (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param user_id [String] User ID to remove
      # @return [Hash] Success response
      def remove_member(workspace_id, card_id, user_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        user = safe_id("user_id", user_id)
        delete("/#{ws}/cards/#{card}/members/#{user}")
      end

      # Creates a checklist on a card.
      # API: POST /:workspace/cards/:card/checklists (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param title [String] Checklist title
      # @return [Hash] Created checklist
      def create_checklist(workspace_id, card_id, title:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        post("/#{ws}/cards/#{card}/checklists", body: { title: title })
      end

      # Adds an item to a checklist.
      # API: POST /:workspace/cards/:card/checklists/:checklist/items (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param title [String] Item title
      # @param checked [Boolean] Whether item is checked (default: false)
      # @return [Hash] Created item
      def add_checklist_item(workspace_id, card_id, checklist_id, title:, checked: false)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)

        post("/#{ws}/cards/#{card}/checklists/#{checklist}/items", body: {
          title: title,
          checklist_id: checklist_id,
          checked: checked
        })
      end

      # Updates a checklist item.
      # API: PATCH /:workspace/cards/:card/checklists/:checklist/items/:item (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param item_id [String] Item ID
      # @param params [Hash] Update parameters (title, checked)
      # @return [Hash] Updated item
      def update_checklist_item(workspace_id, card_id, checklist_id, item_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)
        item = safe_id("item_id", item_id)

        patch("/#{ws}/cards/#{card}/checklists/#{checklist}/items/#{item}",
              body: build_params(**params))
      end

      # Deletes a checklist item.
      # API: DELETE /:workspace/cards/:card/checklists/:checklist/items/:item (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param item_id [String] Item ID
      # @return [Hash] Success response
      def delete_checklist_item(workspace_id, card_id, checklist_id, item_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)
        item = safe_id("item_id", item_id)

        delete("/#{ws}/cards/#{card}/checklists/#{checklist}/items/#{item}")
      end

      # Updates a checklist title.
      # API: PATCH /:workspace/cards/:card/checklists/:checklist (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @param title [String] New title
      # @return [Hash] Updated checklist
      def update_checklist(workspace_id, card_id, checklist_id, title:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)

        patch("/#{ws}/cards/#{card}/checklists/#{checklist}", body: { title: title })
      end

      # Deletes a checklist.
      # API: DELETE /:workspace/cards/:card/checklists/:checklist (undocumented)
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param checklist_id [String] Checklist ID
      # @return [Hash] Success response
      def delete_checklist(workspace_id, card_id, checklist_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)

        delete("/#{ws}/cards/#{card}/checklists/#{checklist}")
      end

      # Gets available tags for a workspace.
      # API: GET /:workspace/tags
      #
      # @param workspace_id [String] Workspace ID
      # @param project_id [String] Optional project ID to filter by
      # @param all [Boolean] Whether to get all tags
      # @return [Hash] List of tags
      def tags(workspace_id, project_id: nil, all: nil)
        ws = safe_id("workspace_id", workspace_id)
        params = build_params(project_id: project_id, all: all)
        get("/#{ws}/tags", params: params)
      end

      # Adds tags to a card.
      # API: POST /:workspace/cards/:card/tags
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param tag_ids [Array<String>, String] Tag ID(s) to add
      # @return [Hash] Result
      def add_tags(workspace_id, card_id, tag_ids:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)

        body = tag_ids.is_a?(Array) ? { ids: tag_ids } : { id: tag_ids }
        post("/#{ws}/cards/#{card}/tags", body: body)
      end

      # Removes a tag from a card.
      # API: DELETE /:workspace/cards/:card/tags/:tag
      #
      # @param workspace_id [String] Workspace ID
      # @param card_id [String] Card ID
      # @param tag_id [String] Tag ID to remove
      # @return [Hash] Success response
      def remove_tag(workspace_id, card_id, tag_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        tag = safe_id("tag_id", tag_id)
        delete("/#{ws}/cards/#{card}/tags/#{tag}")
      end
    end
  end
end
