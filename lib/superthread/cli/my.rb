# frozen_string_literal: true

module Superthread
  module Cli
    # CLI commands for personal shortcuts.
    # Provides quick access to cards, boards, and workspaces for the current user.
    class My < Base
      desc "cards", "List cards assigned to me"
      option :board, type: :string, aliases: "-b", desc: "Filter by board (ID or name)"
      option :space, type: :string, aliases: "-s", desc: "Space (ID or name) - helps resolve board"
      option :today, type: :boolean, desc: "Only cards due today"
      option :overdue, type: :boolean, desc: "Only overdue cards"
      option :week, type: :boolean, desc: "Cards due this week"
      def cards
        handle_error do
          opts = symbolized_options(:archived)
          opts[:board_id] = board_id if options[:board]

          cards = client.cards.assigned(workspace_id, user_id: current_user_id, **opts)

          # Apply date filters client-side
          cards = filter_by_date(cards)

          output_list cards, columns: %i[id title priority due_date list_title], headers: {list_title: "LIST"}
        end
      end

      desc "boards", "List boards I'm a member of"
      option :space, type: :string, aliases: "-s", desc: "Filter by space (ID or name)"
      def boards
        handle_error do
          # Get all boards, optionally filtered by space
          boards = if options[:space]
            client.boards.list(workspace_id, space_id: space_id)
          else
            all_boards
          end

          output_list boards, columns: %i[id title space_id]
        end
      end

      desc "workspaces", "List my workspaces"
      def workspaces
        handle_error do
          user = client.users.me

          if json_output?
            output_item user, fields: %i[teams]
          elsif user.teams&.any?
            rows = user.teams.map do |team|
              {id: team.id, name: team.team_name, role: team.role}
            end
            puts Formatter.table(rows, columns: %i[id name role], color_enabled: color_enabled?)
          else
            say "No workspaces found.", :yellow
          end
        end
      end

      private

      # Get the current user's ID, cached for the session.
      def current_user_id
        @current_user_id ||= begin
          user = client.users.me
          user.user_id || user.id
        end
      end

      # Filter cards by date options (--today, --overdue, --week).
      def filter_by_date(cards)
        return cards unless options[:today] || options[:overdue] || options[:week]

        now = Time.now
        today_start = Time.new(now.year, now.month, now.day).to_i * 1000
        today_end = today_start + (24 * 60 * 60 * 1000) - 1
        week_end = today_start + (7 * 24 * 60 * 60 * 1000) - 1

        cards.select do |card|
          next false unless card.due_date

          if options[:overdue]
            card.due_date < today_start
          elsif options[:today]
            card.due_date.between?(today_start, today_end)
          elsif options[:week]
            card.due_date.between?(today_start, week_end)
          else
            true
          end
        end
      end

      # Get all boards across all spaces.
      def all_boards
        spaces = client.spaces.list(workspace_id)
        spaces.flat_map do |space|
          boards = client.boards.list(workspace_id, space_id: space.id).to_a
          # Annotate each board with its space_id (API doesn't return it)
          boards.each { |board| board.space_id = space.id }
          boards
        rescue Superthread::ApiError
          [] # Skip spaces we can't access
        end
      end
    end
  end
end
