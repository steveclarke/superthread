# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for managing Superthread cards.
    #
    # Provides subcommands for listing, creating, updating, and deleting cards,
    # as well as managing card assignments, relationships, checklists, and tags.
    class Cards < Base
      include Concerns::DateParsable

      # Valid relationship types for linking cards.
      LINK_RELATION_TYPES = %w[blocks blocked_by related duplicates].freeze

      desc "list", "List cards on a board or sprint"
      option :board, type: :string, aliases: "-b", desc: "Board (ID or name, required unless --sprint)"
      option :sprint, type: :string, desc: "Sprint (ID or name, required unless --board)"
      option :space, type: :string, aliases: "-s", desc: "Space (required for --sprint, helps resolve board name)"
      option :list, type: :string, aliases: "-l", desc: "List to filter by (ID or name)"
      option :include_archived, type: :boolean, desc: "Include archived cards"
      option :since, type: :string, desc: "Filter by created date (e.g., 'friday', '3 days ago', '2026-01-20')"
      option :updated_since, type: :string, desc: "Filter by updated date"
      # List cards on a board or sprint with optional filtering.
      #
      # @return [void]
      # @raise [Thor::Error] if neither --board nor --sprint is provided
      # @raise [Thor::Error] if --sprint is used without --space
      def list
        handle_error do
          raise Thor::Error, "Either --board or --sprint is required" unless options[:board] || options[:sprint]
          require_space_for_sprint!

          opts = {}
          opts[:archived] = options[:include_archived] if options[:include_archived]

          if options[:sprint]
            opts[:sprint_id] = sprint_id
            opts[:project_id] = space_id
          else
            opts[:board_id] = board_id
          end

          opts[:list_id] = resolve_list(options[:list]) if options[:list]
          cards = client.cards.list(workspace_id, **opts)

          # Client-side date filtering (API doesn't support time-based filters)
          cards = apply_date_filters(cards)

          enrich_members(cards)
          output_list cards, columns: %i[id title priority list_title members],
            headers: {id: "CARD_ID", list_title: "LIST"}
        end
      end

      desc "search TERM", "Search for cards across boards and spaces"
      option :space, type: :string, aliases: "-s", desc: "Space to filter by (ID or name)"
      option :status, type: :string, desc: "Status filter (comma-separated)"
      option :field, type: :string, enum: %w[title content], desc: "Search in title or content"
      option :include_archived, type: :boolean, desc: "Include archived cards"
      # Search for cards by keyword with rich output.
      #
      # @param term [String] the search term
      # @return [void]
      def search(term)
        handle_error do
          statuses = options[:status]&.split(",")&.map(&:strip)
          results = client.search.query(
            workspace_id,
            query: term,
            types: ["card"],
            statuses: statuses,
            field: options[:field],
            space_id: (space_id if options[:space]),
            archived: options[:include_archived],
            limit: effective_limit
          )

          card_ids = results.map { |r| r[:id] }.compact
          if card_ids.empty?
            say "No cards found matching '#{term}'.", :yellow unless options[:quiet]
            return
          end

          cards = card_ids.filter_map do |id|
            client.cards.find(workspace_id, id)
          rescue Superthread::NotFoundError, Superthread::ForbiddenError
            nil
          end

          if cards.empty?
            say "No cards found matching '#{term}'.", :yellow unless options[:quiet]
            return
          end

          enrich_members(cards)
          output_list cards, columns: %i[id title priority list_title board_title members],
            headers: {id: "CARD_ID", list_title: "LIST", board_title: "BOARD"}
        end
      end

      desc "get CARD", "Get card details"
      option :raw, type: :boolean, desc: "Show raw content without markdown rendering"
      option :no_content, type: :boolean, desc: "Hide content, show only metadata"
      # Display detailed information about a specific card.
      #
      # @param card_id [String] the unique identifier of the card to retrieve
      # @return [void]
      def get(card_id)
        handle_error do
          begin
            card = client.cards.find(workspace_id, card_id)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Card not found: '#{card_id}'. Use 'suth cards list -b BOARD' to see available cards."
          end

          enrich_members(card)

          if json_output?
            fields = %i[id title status priority list_title board_title
              members start_date due_date time_created time_updated
              parent_card child_cards linked_cards checklists]
            fields.insert(2, :content) unless options[:no_content]
            output_item card, fields: fields, labels: {
              id: "Card ID",
              list_title: "List Title",
              board_title: "Board Title",
              parent_card: "Parent Card",
              child_cards: "Child Cards",
              linked_cards: "Linked Cards",
              start_date: "Start Date",
              due_date: "Due Date",
              time_created: "Time Created",
              time_updated: "Time Updated"
            }
          else
            # Output metadata fields (status used for coloring list, not shown separately)
            output_item card,
              fields: %i[id title priority list_title board_title
                members start_date due_date time_created time_updated],
              labels: {
                id: "Card ID",
                list_title: "List",
                board_title: "Board",
                start_date: "Start Date",
                due_date: "Due Date",
                time_created: "Time Created",
                time_updated: "Time Updated"
              }

            # Output card relationships
            output_card_relationships(card)

            # Output checklists
            output_card_checklists(card)

            # Render content separately with markdown formatting
            if !options[:no_content] && card.content && !card.content.empty?
              puts ""
              Ui.section "Content"
              if options[:raw]
                puts card.content
              else
                puts Ui.render_markdown(card.content)
              end
            end
          end
        end
      end

      desc "create", "Create a new card"
      option :title, type: :string, required: true, desc: "Card title"
      option :list, type: :string, required: true, aliases: "-l", desc: "Destination list (ID or name)"
      option :board, type: :string, aliases: "-b", desc: "Board (ID or name, required unless --sprint)"
      option :space, type: :string, aliases: "-s", desc: "Space (required for --sprint, helps resolve board name)"
      option :sprint, type: :string, desc: "Sprint (ID or name, required unless --board)"
      option :content, type: :string, desc: "Card content (HTML). Use {{@Name}} to mention users"
      option :project, type: :string, desc: "Project ID"
      option :start_date, type: :numeric, desc: "Start date (Unix timestamp)"
      option :due_date, type: :numeric, desc: "Due date (Unix timestamp)"
      option :priority, type: :numeric, desc: "Priority level (1=low, 4=urgent)"
      option :parent_card, type: :string, desc: "Parent card ID"
      option :epic, type: :string, desc: "Epic ID"
      option :owner, type: :string, aliases: "-o", desc: "Owner (user ID, name, or email)"
      # Create a new card on a board or sprint.
      #
      # @return [void]
      # @raise [Thor::Error] if neither --board nor --sprint is provided
      def create
        handle_error do
          raise Thor::Error, "Either --board or --sprint is required" unless options[:board] || options[:sprint]
          require_space_for_sprint!

          opts = symbolized_options(:title, :content, :start_date, :due_date, :priority)
          opts[:list_id] = resolve_list(options[:list])
          opts[:board_id] = board_id if options[:board]
          opts[:sprint_id] = sprint_id if options[:sprint]
          opts[:project_id] = options[:project] || (space_id if options[:sprint])
          opts[:parent_card_id] = options[:parent_card] if options[:parent_card]
          opts[:epic_id] = options[:epic] if options[:epic]
          opts[:owner_id] = resolve_user(options[:owner]) if options[:owner]
          card = client.cards.create(workspace_id, **opts)
          output_item card, labels: {id: "Card ID"}
        end
      end

      desc "update CARD", "Update a card"
      option :title, type: :string, desc: "New title"
      option :content, type: :string, desc: "Card content (HTML). Use {{@Name}} to mention users"
      option :list, type: :string, aliases: "-l", desc: "Destination list (ID or name)"
      option :board, type: :string, aliases: "-b", desc: "Board (helps resolve list name)"
      option :sprint, type: :string, desc: "Sprint to move card to (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (required for --sprint, helps resolve board/list name)"
      option :position, type: :numeric, desc: "Position within the list (0 = top)"
      option :priority, type: :numeric, desc: "Priority level (1=low, 4=urgent)"
      option :epic, type: :string, desc: "Epic ID"
      option :archived, type: :boolean, desc: "Archive/unarchive"
      # Update an existing card's properties.
      #
      # Content is updated via a separate PUT endpoint since the standard
      # PATCH endpoint does not support content changes.
      #
      # @param card_id [String] the unique identifier of the card to update
      # @return [void]
      def update(card_id)
        handle_error do
          require_space_for_sprint!

          begin
            # Update content via dedicated PUT endpoint (separate from PATCH)
            if options[:content]
              client.cards.update_content(workspace_id, card_id, content: options[:content])
            end

            # Update other fields via PATCH (skip if only content was provided)
            has_patch_fields = options[:title] || options[:list] || options[:priority] ||
              !options[:archived].nil? || options[:epic] || options[:position] || options[:sprint]

            if has_patch_fields
              # WORKAROUND: API ignores title when combined with list_id,
              # so we make separate requests when both are provided.
              # TODO: Remove when API is fixed (https://superthread.com/api/known-issues)
              if options[:list] && (options[:title] || options[:priority] || !options[:archived].nil? || options[:epic])
                # First update non-move fields
                field_opts = symbolized_options(:title, :priority, :archived)
                field_opts[:epic_id] = options[:epic] if options[:epic]
                client.cards.update(workspace_id, card_id, **field_opts) unless field_opts.empty?

                # Then move the card (include sprint context)
                move_opts = resolve_list_with_context(options[:list], card_id)
                move_opts[:position] = options[:position] if options[:position]
                card = client.cards.update(workspace_id, card_id, **move_opts)
              else
                opts = symbolized_options(:title, :priority, :archived)
                opts[:epic_id] = options[:epic] if options[:epic]
                opts[:position] = options[:position] if options[:position]

                if options[:list]
                  opts.merge!(resolve_list_with_context(options[:list], card_id))
                elsif options[:sprint]
                  # Moving to a sprint without --list — default to first list
                  opts[:sprint_id] = sprint_id
                  opts[:project_id] = space_id
                  sprint_obj = client.sprints.find(workspace_id, sprint_id, space_id: space_id)
                  opts[:list_id] = sprint_obj.lists.first&.id
                end

                card = client.cards.update(workspace_id, card_id, **opts)
              end
            end

            # If only content was updated, fetch the card for output
            card ||= client.cards.find(workspace_id, card_id)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Card not found: '#{card_id}'. Use 'suth cards list -b BOARD' to see available cards."
          end
          output_item card, labels: {id: "Card ID"}
        end
      end

      desc "delete CARD", "Delete a card"
      # Permanently delete a card after confirmation.
      #
      # @param card_ref [String] the card ID or reference to delete
      # @return [void]
      def delete(card_ref)
        handle_error do
          begin
            card = client.cards.find(workspace_id, card_ref)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Card not found: '#{card_ref}'. Use 'suth cards list -b BOARD' to see available cards."
          end
          confirming("Delete card '#{card.title}' (#{card.id})?") do
            client.cards.destroy(workspace_id, card.id)
            output_success "Card '#{card.title}' deleted"
          end
        end
      end

      desc "duplicate CARD", "Duplicate a card"
      option :title, type: :string, desc: "Title for the duplicated card"
      option :project, type: :string, required: true, desc: "Destination project ID"
      option :board, type: :string, required: true, aliases: "-b", desc: "Destination board (ID or name)"
      option :list, type: :string, required: true, aliases: "-l", desc: "Destination list (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      # Create a copy of an existing card in a specified location.
      #
      # @param card_id [String] the unique identifier of the card to duplicate
      # @return [void]
      def duplicate(card_id)
        handle_error do
          begin
            opts = symbolized_options(:title)
            opts[:project_id] = options[:project]
            opts[:board_id] = board_id
            opts[:list_id] = resolve_list(options[:list])
            card = client.cards.duplicate(workspace_id, card_id, **opts)
          rescue Superthread::ForbiddenError, Superthread::NotFoundError
            raise Thor::Error, "Card not found: '#{card_id}'. Use 'suth cards list -b BOARD' to see available cards."
          end
          output_item card, labels: {id: "Card ID"}
        end
      end

      desc "assigned USER", "Get cards assigned to a user"
      option :board, type: :string, aliases: "-b", desc: "Board to filter by (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (helps resolve board name)"
      option :project, type: :string, desc: "Project to filter by (ID)"
      option :include_archived, type: :boolean, desc: "Include archived cards"
      option :since, type: :string, desc: "Filter by created date (e.g., 'friday', '3 days ago', '2026-01-20')"
      option :updated_since, type: :string, desc: "Filter by updated date"
      # List all cards assigned to a specific user.
      #
      # @param user_ref [String] the user ID, name, or email to look up assignments for
      # @return [void]
      def assigned(user_ref)
        handle_error do
          opts = {}
          opts[:archived] = options[:include_archived] if options[:include_archived]
          opts[:user_id] = resolve_user(user_ref)
          opts[:board_id] = board_id if options[:board]
          opts[:project_id] = options[:project] if options[:project]
          cards = client.cards.assigned(workspace_id, **opts)

          # Client-side date filtering (API doesn't support time-based filters)
          cards = apply_date_filters(cards)

          enrich_members(cards)
          output_list cards, columns: %i[id title priority list_title members],
            headers: {id: "CARD_ID", list_title: "LIST"}
        rescue Superthread::ForbiddenError, Superthread::NotFoundError
          raise Thor::Error, "User not found: '#{user_ref}'. Use 'suth members list' to see available users."
        end
      end

      desc "assign CARD_ID USERS", "Assign user(s) to a card (comma-separated)"
      option :role, type: :string, default: "member", desc: "Member role"
      # Add one or more users as members of a card.
      #
      # @param card_id [String] the unique identifier of the card
      # @param user_refs [String] comma-separated user IDs, names, or emails to assign
      # @return [void]
      def assign(card_id, user_refs)
        handle_error do
          users = user_refs.split(",").map(&:strip)
          users.each do |user_ref|
            user_id = resolve_user(user_ref)
            client.cards.add_member(workspace_id, card_id, user_id: user_id, role: options[:role])
          end
          output_success "Assigned #{users.size} user(s) to card #{card_id}"
        end
      end

      desc "unassign CARD_ID USERS", "Unassign user(s) from a card (comma-separated)"
      # Remove one or more users from a card.
      #
      # @param card_id [String] the unique identifier of the card
      # @param user_refs [String] comma-separated user IDs, names, or emails to unassign
      # @return [void]
      def unassign(card_id, user_refs)
        handle_error do
          users = user_refs.split(",").map(&:strip)
          users.each do |user_ref|
            user_id = resolve_user(user_ref)
            client.cards.remove_member(workspace_id, card_id, user_id)
          end
          output_success "Unassigned #{users.size} user(s) from card #{card_id}"
        end
      end

      desc "link", "Link two cards"
      option :card, type: :string, required: true, aliases: "-c", desc: "Card ID"
      option :related, type: :string, required: true, aliases: "-r", desc: "Related card ID"
      option :type, type: :string, required: true,
        desc: "Relationship type (blocks, blocked_by, related, duplicates)"
      # Create a relationship between two cards.
      #
      # @return [void]
      def link
        handle_error do
          unless LINK_RELATION_TYPES.include?(options[:type])
            if %w[parent child].include?(options[:type])
              raise Thor::Error,
                "Parent/child relationships are set via --parent-card on 'suth cards create' or 'suth cards update'"
            end
            raise Thor::Error,
              "Expected '--type' to be one of #{LINK_RELATION_TYPES.join(", ")}; got #{options[:type]}"
          end
          client.cards.add_related(
            workspace_id, options[:card],
            related_card_id: options[:related],
            relation_type: options[:type]
          )
          output_success "Linked #{options[:card]} -> #{options[:related]} (#{options[:type]})"
        end
      end

      desc "unlink", "Remove card relationship"
      option :card, type: :string, required: true, aliases: "-c", desc: "Card ID"
      option :related, type: :string, required: true, aliases: "-r", desc: "Related card ID"
      # Remove an existing relationship between two cards.
      #
      # @return [void]
      def unlink
        handle_error do
          client.cards.remove_related(workspace_id, options[:card], options[:related])
          output_success "Unlinked #{options[:card]} from #{options[:related]}"
        end
      end

      desc "tag CARD_ID TAGS", "Add tags to card (comma-separated IDs or names)"
      # Apply one or more tags to a card.
      #
      # @param card_id [String] the unique identifier of the card
      # @param tag_refs [String] comma-separated tag IDs or names to add
      # @return [void]
      def tag(card_id, tag_refs)
        handle_error do
          ids = tag_refs.split(",").map { |ref| resolve_tag(ref.strip) }
          client.cards.add_tags(workspace_id, card_id, tag_ids: ids)
          output_success "Added #{ids.count} tag(s) to card #{card_id}"
        end
      end

      desc "untag CARD_ID TAG", "Remove tag from card"
      # Remove a tag from a card.
      #
      # @param card_id [String] the unique identifier of the card
      # @param tag_ref [String] the tag ID or name to remove
      # @return [void]
      def untag(card_id, tag_ref)
        handle_error do
          tag_id = resolve_tag(tag_ref)
          client.cards.remove_tag(workspace_id, card_id, tag_id)
          output_success "Removed tag #{tag_ref} from card #{card_id}"
        end
      end

      private

      # Override Base#effective_limit for search-specific defaults.
      # Returns nil for --limit 0 (unlimited), 30 for search default.
      #
      # @return [Integer, nil] the limit (nil = unlimited when --limit 0)
      def effective_limit
        limit = options[:limit]
        return nil if limit == 0
        (limit.is_a?(Integer) && limit > 0) ? limit : 30
      end

      # Enrich card members with display names from workspace users.
      #
      # The API returns members with only user_id. This fetches the workspace
      # member list once and sets display_name on each member object.
      #
      # @param cards [Array<Card>, Card] card(s) whose members to enrich
      # @return [void]
      def enrich_members(cards)
        cards = Array(cards)
        return unless cards.any? { |c| c.members.any? }

        user_names = workspace_users.each_with_object({}) do |u, h|
          h[u.user_identifier] = u.display_name
        end

        cards.each do |card|
          card.members.each do |member|
            member.display_name ||= user_names[member.user_id]
          end
        end
      end

      # Resolve a list reference and include sprint context when needed.
      #
      # The API requires sprint_id and project_id alongside list_id when moving
      # cards within a sprint. This method handles three scenarios:
      # 1. --board or --sprint given: resolve list name with that context
      # 2. Neither given: fetch the card to discover its sprint/board context
      # 3. Card is on a board (no sprint): resolve normally
      #
      # @param list_ref [String] the list ID or name to resolve
      # @param card_id [String] the card identifier to look up for context
      # @return [Hash] params hash with :list_id and optional :sprint_id, :project_id
      def resolve_list_with_context(list_ref, card_id)
        result = {}

        if options[:board] || options[:sprint]
          result[:list_id] = resolve_list(list_ref)
          if options[:sprint]
            result[:sprint_id] = sprint_id
            result[:project_id] = space_id
          end
        else
          existing = client.cards.find(workspace_id, card_id)
          if existing.sprint_id
            sprint_obj = client.sprints.find(workspace_id, existing.sprint_id,
              space_id: existing.project_id)
            list = sprint_obj.lists&.find { |l| l.title&.downcase == list_ref.downcase }
            unless list || looks_like_id?(list_ref)
              available = sprint_obj.lists&.map(&:title)&.join(", ") || "none"
              raise Thor::Error, "List '#{list_ref}' not found in sprint. Available: #{available}"
            end
            result[:list_id] = list ? list.id : list_ref
            result[:sprint_id] = existing.sprint_id
            result[:project_id] = existing.project_id
          elsif looks_like_id?(list_ref)
            result[:list_id] = list_ref
          else
            board = client.boards.find(workspace_id, existing.board_id)
            list = board.lists&.find { |l| l.title&.downcase == list_ref.downcase }
            unless list
              available = board.lists&.map(&:title)&.join(", ") || "none"
              raise Thor::Error, "List '#{list_ref}' not found on board. Available: #{available}"
            end
            result[:list_id] = list.id
          end
        end

        result
      end

      # Apply date filters to a collection of cards.
      # The API doesn't support time-based filtering, so we filter client-side.
      #
      # @param cards [Enumerable] the cards to apply --since and --updated_since filters to
      # @return [Array] Filtered cards
      def apply_date_filters(cards)
        since_ts = parse_date(options[:since]) if options[:since]
        updated_ts = parse_date(options[:updated_since]) if options[:updated_since]
        return cards.to_a unless since_ts || updated_ts

        cards.to_a.select do |card|
          (since_ts.nil? || meets_date_threshold?(card.time_created, since_ts)) &&
            (updated_ts.nil? || meets_date_threshold?(card.time_updated, updated_ts))
        end
      end

      # Check if a timestamp meets a minimum threshold after normalization.
      #
      # @param timestamp [Object] the raw timestamp value from the model
      # @param threshold [Integer] the minimum Unix timestamp
      # @return [Boolean] true if the normalized timestamp meets or exceeds the threshold
      def meets_date_threshold?(timestamp, threshold)
        ts = Formatter.normalize_timestamp(timestamp)
        ts && ts >= threshold
      end

      # Output card relationships (parent, children, links) in human-readable format.
      #
      # @param card [Card] the card object containing relationship data
      # @return [void]
      def output_card_relationships(card)
        has_relationships = card.parent || card.children.any? || card.links.any?
        return unless has_relationships

        puts ""
        Ui.section "Relationships"

        Ui.kv("Parent", card.parent.to_s) if card.parent

        if card.children.any?
          Ui.kv("Children", "")
          card.children.each { |child| puts "  #{child}" }
        end

        if card.links.any?
          card.links_by_type.each do |type, links|
            label = type.tr("_", " ").capitalize
            Ui.kv(label, "")
            links.each { |link| puts "  #{link}" }
          end
        end
      end

      # Output card checklists with items in human-readable format.
      #
      # @param card [Card] the card object containing checklist data
      # @return [void]
      def output_card_checklists(card)
        return unless card.checklists&.any?

        puts ""
        Ui.section "Checklists"

        card.checklists.each do |checklist|
          progress = "(#{checklist.completed_count}/#{checklist.total_count})"
          Ui.kv(checklist.title, progress)
          checklist.sorted_items.each do |item|
            marker = item.checked? ? "✓" : "○"
            title = item.title.gsub(/<[^>]*>/, "").strip
            puts "  #{marker} #{title}"
          end
        end
      end
    end
  end
end
