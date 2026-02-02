# frozen_string_literal: true

module Superthread
  module Resources
    # API resource for card (task/issue) operations.
    #
    # Provides methods for creating, updating, listing, and managing cards
    # including their members, checklists, tags, and relationships.
    class Cards < Base
      # Creates a new card on a board or in a sprint.
      #
      # @param workspace_id [String] the workspace identifier
      # @param params [Hash{Symbol => Object}] card creation parameters
      # @option params [String] :title the card title (required)
      # @option params [String] :list_id the list identifier (required)
      # @option params [String] :board_id the board identifier (required unless sprint_id provided)
      # @option params [String] :sprint_id the sprint identifier (required unless board_id provided)
      # @option params [String] :content the card content as HTML
      # @option params [String] :project_id the project/space identifier
      # @option params [Integer] :start_date the start date as Unix timestamp
      # @option params [Integer] :due_date the due date as Unix timestamp
      # @option params [Integer] :priority the priority level (1-4)
      # @option params [Integer] :estimate the story point estimate
      # @option params [String] :parent_card_id the parent card identifier for subtasks
      # @option params [String] :epic_id the epic/project identifier to link to
      # @option params [String] :owner_id the owner user identifier
      # @return [Superthread::Models::Card] the created card
      # @raise [ArgumentError] if neither board_id nor sprint_id is provided
      def create(workspace_id, **params)
        unless params[:board_id] || params[:sprint_id]
          raise ArgumentError, "Either board_id or sprint_id must be provided"
        end

        ws = safe_id("workspace_id", workspace_id)
        post_object("/#{ws}/cards", body: params,
          object_class: Models::Card, unwrap_key: :card)
      end

      # Updates an existing card's attributes.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new card title
      # @option params [String] :list_id the new list identifier to move the card
      # @option params [Integer] :start_date the new start date as Unix timestamp
      # @option params [Integer] :due_date the new due date as Unix timestamp
      # @option params [Integer] :priority the new priority level (1-4)
      # @option params [Integer] :estimate the new story point estimate
      # @option params [String] :parent_card_id the new parent card identifier
      # @option params [String] :epic_id the new epic identifier
      # @option params [Boolean] :archived whether the card is archived
      # @return [Superthread::Models::Card] the updated card
      # @note Content cannot be updated via this API; it uses WebSocket collaboration.
      def update(workspace_id, card_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        patch_object("/#{ws}/cards/#{card}", body: compact_params(**params),
          object_class: Models::Card, unwrap_key: :card)
      end

      # Gets a specific card with full details.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @return [Superthread::Models::Card] the card with all attributes
      def find(workspace_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        get_object("/#{ws}/cards/#{card}",
          object_class: Models::Card, unwrap_key: :card)
      end

      # Deletes a card permanently.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def destroy(workspace_id, card_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        http_delete("/#{ws}/cards/#{card}")
        success_response
      end

      # Duplicates a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier to duplicate
      # @param params [Hash{Symbol => Object}] optional destination parameters
      # @option params [String] :board_id the destination board identifier
      # @option params [String] :list_id the destination list identifier
      # @option params [String] :sprint_id the destination sprint identifier
      # @return [Superthread::Models::Card] the duplicated card
      def duplicate(workspace_id, card_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        post_object("/#{ws}/cards/#{card}/copy", body: compact_params(**params),
          object_class: Models::Card, unwrap_key: :card)
      end

      # Lists cards with optional filters.
      #
      # @param workspace_id [String] the workspace identifier
      # @param filters [Hash{Symbol => Object}] filter options
      # @option filters [String] :board_id filter by board identifier
      # @option filters [String] :list_id filter by list identifier
      # @option filters [String] :project_id filter by project/space identifier
      # @option filters [Boolean] :archived when true, includes archived cards
      # @return [Superthread::Objects::Collection<Superthread::Models::Card>] the matching cards
      def list(workspace_id, **filters)
        ws = safe_id("workspace_id", workspace_id)

        body = {
          type: "card",
          card_filters: {}
        }

        body[:card_filters][:is_archived] = filters[:archived] unless filters[:archived].nil?
        body[:card_filters][:include] = {}
        body[:card_filters][:include][:boards] = [filters[:board_id]] if filters[:board_id]
        body[:card_filters][:include][:lists] = [filters[:list_id]] if filters[:list_id]
        body[:card_filters][:include][:projects] = [filters[:project_id]] if filters[:project_id]

        post_collection("/#{ws}/views/preview", body: body,
          item_class: Models::Card, items_key: :cards)
      end

      # Gets cards assigned to a user.
      #
      # @param workspace_id [String] the workspace identifier
      # @param user_id [String] the user identifier to filter by assignment
      # @param filters [Hash{Symbol => Object}] optional additional filters
      # @option filters [String] :board_id filter by board identifier
      # @option filters [String] :list_id filter by list identifier
      # @option filters [String] :project_id filter by project/space identifier
      # @option filters [Boolean] :archived when true, includes archived cards
      # @return [Superthread::Objects::Collection<Superthread::Models::Card>] the user's assigned cards
      def assigned(workspace_id, user_id:, **filters)
        ws = safe_id("workspace_id", workspace_id)

        body = {
          type: "card",
          card_filters: {
            include: {members: [user_id]}
          }
        }

        body[:card_filters][:is_archived] = filters[:archived] unless filters[:archived].nil?
        body[:card_filters][:include][:boards] = [filters[:board_id]] if filters[:board_id]
        body[:card_filters][:include][:lists] = [filters[:list_id]] if filters[:list_id]
        body[:card_filters][:include][:projects] = [filters[:project_id]] if filters[:project_id]

        post_collection("/#{ws}/views/preview", body: body,
          item_class: Models::Card, items_key: :cards)
      end

      # Links two cards with a relationship.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the source card identifier
      # @param related_card_id [String] the card identifier to link to
      # @param relation_type [String] the relationship type (blocks, blocked_by, related, duplicates)
      # @return [Superthread::Object] the link result
      def add_related(workspace_id, card_id, related_card_id:, relation_type:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)

        post_object("/#{ws}/cards/#{card}/linked_cards", body: {
          card_id: related_card_id,
          linked_card_type: relation_type
        })
      end

      # Removes a card relationship.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the source card identifier
      # @param linked_card_id [String] the linked card identifier to remove
      # @return [Superthread::Object] a response object with success: true
      def remove_related(workspace_id, card_id, linked_card_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        linked = safe_id("linked_card_id", linked_card_id)
        http_delete("/#{ws}/cards/#{card}/linked_cards/#{linked}")
        success_response
      end

      # Adds a member to a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param user_id [String] the user identifier to add as a member
      # @param role [String] the member role (defaults to "member")
      # @return [Superthread::Object] the membership result
      def add_member(workspace_id, card_id, user_id:, role: "member")
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        post_object("/#{ws}/cards/#{card}/members", body: {user_id: user_id, role: role})
      end

      # Removes a member from a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param user_id [String] the user identifier to remove
      # @return [Superthread::Object] a response object with success: true
      def remove_member(workspace_id, card_id, user_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        user = safe_id("user_id", user_id)
        http_delete("/#{ws}/cards/#{card}/members/#{user}")
        success_response
      end

      # Creates a checklist on a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param title [String] the checklist title
      # @return [Superthread::Models::Checklist] the created checklist
      def create_checklist(workspace_id, card_id, title:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        post_object("/#{ws}/cards/#{card}/checklists", body: {title: title},
          object_class: Models::Checklist, unwrap_key: :checklist)
      end

      # Adds an item to a checklist.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param checklist_id [String] the checklist identifier
      # @param title [String] the item title
      # @param checked [Boolean] whether the item is checked (defaults to false)
      # @return [Superthread::Models::ChecklistItem] the created checklist item
      def add_checklist_item(workspace_id, card_id, checklist_id, title:, checked: false)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)

        post_object("/#{ws}/cards/#{card}/checklists/#{checklist}/items", body: {
          title: title,
          checklist_id: checklist_id,
          checked: checked
        }, object_class: Models::ChecklistItem, unwrap_key: :checklist_item)
      end

      # Updates a checklist item.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param checklist_id [String] the checklist identifier
      # @param item_id [String] the item identifier
      # @param params [Hash{Symbol => Object}] the attributes to update
      # @option params [String] :title the new item title
      # @option params [Boolean] :checked whether the item is checked
      # @return [Superthread::Models::ChecklistItem] the updated checklist item
      def update_checklist_item(workspace_id, card_id, checklist_id, item_id, **params)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)
        item = safe_id("item_id", item_id)

        patch_object("/#{ws}/cards/#{card}/checklists/#{checklist}/items/#{item}",
          body: compact_params(**params), object_class: Models::ChecklistItem, unwrap_key: :checklist_item)
      end

      # Deletes a checklist item.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param checklist_id [String] the checklist identifier
      # @param item_id [String] the item identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def delete_checklist_item(workspace_id, card_id, checklist_id, item_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)
        item = safe_id("item_id", item_id)

        http_delete("/#{ws}/cards/#{card}/checklists/#{checklist}/items/#{item}")
        success_response
      end

      # Updates a checklist's title.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param checklist_id [String] the checklist identifier
      # @param title [String] the new checklist title
      # @return [Superthread::Models::Checklist] the updated checklist
      def update_checklist(workspace_id, card_id, checklist_id, title:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)

        patch_object("/#{ws}/cards/#{card}/checklists/#{checklist}", body: {title: title},
          object_class: Models::Checklist, unwrap_key: :checklist)
      end

      # Deletes a checklist and all its items.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param checklist_id [String] the checklist identifier to delete
      # @return [Superthread::Object] a response object with success: true
      def delete_checklist(workspace_id, card_id, checklist_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        checklist = safe_id("checklist_id", checklist_id)

        http_delete("/#{ws}/cards/#{card}/checklists/#{checklist}")
        success_response
      end

      # Gets available tags for a workspace.
      #
      # @param workspace_id [String] the workspace identifier
      # @param project_id [String, nil] optional project/space identifier to filter by
      # @param all [Boolean, nil] when true, returns all tags including unused ones
      # @return [Superthread::Objects::Collection<Superthread::Models::Tag>] the available tags
      def tags(workspace_id, project_id: nil, all: nil)
        ws = safe_id("workspace_id", workspace_id)
        params = compact_params(project_id: project_id, all: all)
        get_collection("/#{ws}/tags", params: params,
          item_class: Models::Tag, items_key: :tags)
      end

      # Adds tags to a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param tag_ids [Array<String>, String] the tag identifier(s) to add
      # @return [Superthread::Object] the tagging result
      def add_tags(workspace_id, card_id, tag_ids:)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)

        body = tag_ids.is_a?(Array) ? {ids: tag_ids} : {id: tag_ids}
        post_object("/#{ws}/cards/#{card}/tags", body: body)
      end

      # Removes a tag from a card.
      #
      # @param workspace_id [String] the workspace identifier
      # @param card_id [String] the card identifier
      # @param tag_id [String] the tag identifier to remove
      # @return [Superthread::Object] a response object with success: true
      def remove_tag(workspace_id, card_id, tag_id)
        ws = safe_id("workspace_id", workspace_id)
        card = safe_id("card_id", card_id)
        tag = safe_id("tag_id", tag_id)
        http_delete("/#{ws}/cards/#{card}/tags/#{tag}")
        success_response
      end
    end
  end
end
