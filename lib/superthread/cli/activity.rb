# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for viewing recent activity across the workspace.
    class Activity < Base
      include Concerns::DateParsable

      desc "show", "Show recent activity across workspace"
      option :since, type: :string, default: "today", desc: "Filter by date (e.g., 'friday', '3 days ago')"
      option :user, type: :string, desc: "Filter by user (ID, name, or 'me')"
      option :board, type: :string, aliases: "-b", desc: "Filter by board (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board by name"
      # Display recent activity across the workspace.
      #
      # @return [void]
      def show
        handle_error do
          since_ts = parse_date(options[:since])
          activity = fetch_activity(since_ts)

          if json_output?
            output_activity_json(activity)
          else
            output_activity_summary(activity, options[:since])
          end
        end
      end
      default_task :show

      private

      # Fetch all activity data from the workspace.
      # Returns categorized cards: created, updated, completed.
      #
      # @param since_ts [Integer] Unix timestamp for filtering
      # @return [Hash] Activity data grouped by category
      def fetch_activity(since_ts)
        # If user filter specified, use assigned endpoint
        # Otherwise, we need to get cards differently
        cards = if options[:user]
          user_id = resolve_user(options[:user])
          opts = {user_id: user_id}
          opts[:board_id] = board_id if options[:board]
          client.cards.assigned(workspace_id, **opts).to_a
        elsif options[:board]
          client.cards.list(workspace_id, board_id: board_id).to_a
        else
          # Fetch cards from all boards in the workspace
          fetch_all_cards
        end

        categorize_activity(cards, since_ts)
      end

      # Fetch cards from all boards in the workspace.
      # This is slower but necessary when no board filter is provided.
      #
      # @return [Array<Card>] All cards
      def fetch_all_cards
        spaces = client.spaces.list(workspace_id)
        all_cards = []

        spaces.each do |space|
          boards = client.boards.list(workspace_id, space_id: space.id)
          boards.each do |board|
            cards = client.cards.list(workspace_id, board_id: board.id)
            all_cards.concat(cards.to_a)
          rescue Superthread::ApiError
            # Skip boards we can't access
          end
        rescue Superthread::ApiError
          # Skip spaces we can't access
        end

        all_cards
      end

      # Categorize cards into activity buckets based on timestamps.
      #
      # @param cards [Array<Card>] the cards to sort into created, updated, and completed buckets
      # @param since_ts [Integer] Filter timestamp
      # @return [Hash] Categorized activity
      def categorize_activity(cards, since_ts)
        activity = {
          created: [],
          updated: [],
          completed: []
        }

        cards.each do |card|
          created_ts = normalize_timestamp(card.time_created)
          updated_ts = normalize_timestamp(card.time_updated)
          completed_ts = normalize_timestamp(card.completed_date)

          # Check for completion (takes precedence)
          if completed_ts && completed_ts >= since_ts
            activity[:completed] << card
          # Check for creation
          elsif created_ts && created_ts >= since_ts
            activity[:created] << card
          # Check for update (but not if just created)
          elsif updated_ts && updated_ts >= since_ts && updated_ts != created_ts
            activity[:updated] << card
          end
        end

        # Sort each category by most recent first
        activity[:created].sort_by! { |c| -(c.time_created || 0) }
        activity[:updated].sort_by! { |c| -(c.time_updated || 0) }
        activity[:completed].sort_by! { |c| -(c.completed_date || 0) }

        activity
      end

      # Normalize timestamp to seconds (API sometimes returns milliseconds).
      #
      # @param ts [Integer, nil] Timestamp
      # @return [Integer, nil] Normalized timestamp in seconds
      def normalize_timestamp(ts)
        return nil if ts.nil? || ts == 0
        (ts > 9_999_999_999) ? ts / 1000 : ts
      end

      # Output activity as JSON.
      #
      # @param activity [Hash] the categorized activity data with :created, :updated, :completed keys
      # @return [void]
      def output_activity_json(activity)
        json_data = {
          created: activity[:created].map { |c| card_to_hash(c) },
          updated: activity[:updated].map { |c| card_to_hash(c) },
          completed: activity[:completed].map { |c| card_to_hash(c) },
          summary: {
            total_created: activity[:created].size,
            total_updated: activity[:updated].size,
            total_completed: activity[:completed].size
          }
        }
        puts Formatter.json(json_data)
      end

      # Convert card to hash for JSON output.
      #
      # @param card [Card] the card to convert
      # @return [Hash] the card data as a hash
      def card_to_hash(card)
        {
          id: card.id,
          title: card.title,
          status: card.status,
          priority: card.priority,
          list_title: card.list_title,
          board_title: card.board_title,
          time_created: card.time_created,
          time_updated: card.time_updated,
          completed_date: card.completed_date
        }
      end

      # Output activity as a formatted summary.
      #
      # @param activity [Hash] the categorized activity data
      # @param since_label [String] the label describing the time period
      # @return [void]
      def output_activity_summary(activity, since_label)
        total = activity[:created].size + activity[:updated].size + activity[:completed].size

        if total == 0
          say "No activity since #{since_label}", :yellow
          return
        end

        Ui.section "Activity since #{since_label}"
        puts ""

        if activity[:completed].any?
          output_activity_section("Completed", activity[:completed], :green)
        end

        if activity[:created].any?
          output_activity_section("Created", activity[:created], :cyan)
        end

        if activity[:updated].any?
          output_activity_section("Updated", activity[:updated], :yellow)
        end

        puts ""
        say "Total: #{total} card(s) (#{activity[:completed].size} completed, " \
            "#{activity[:created].size} created, #{activity[:updated].size} updated)", :white
      end

      # Output a section of activity.
      #
      # @param label [String] the section header label
      # @param cards [Array<Card>] the cards to display in this section
      # @param color [Symbol] the color for the section header
      # @return [void]
      def output_activity_section(label, cards, color)
        say "#{label} (#{cards.size}):", color
        cards.each do |card|
          board_info = card.board_title ? " [#{card.board_title}]" : ""
          list_info = card.list_title ? " -> #{card.list_title}" : ""
          say "  #{card.id}  #{card.title}#{board_info}#{list_info}"
        end
        puts ""
      end
    end
  end
end
