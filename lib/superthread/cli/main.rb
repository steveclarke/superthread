# frozen_string_literal: true

module Superthread
  module Cli
    # Main entry point for the Superthread CLI.
    # Registers all subcommands and provides top-level commands like version and setup.
    class Main < Base
      map %w[--version -V] => :version

      desc "version", "Show version"
      # Displays the current version of the Superthread CLI.
      #
      # @return [void]
      def version
        puts "superthread #{Superthread::VERSION}"
      end

      desc "setup", "Interactive setup wizard"
      # Runs the interactive setup wizard to configure accounts and workspaces.
      #
      # @return [void]
      def setup
        Superthread::Cli::Setup.execute
      end

      desc "config SUBCOMMAND", "Manage configuration"
      subcommand "config", Superthread::Cli::Config

      desc "me", "Show current user account info"
      # Displays information about the currently authenticated user.
      #
      # @return [void]
      def me
        handle_error do
          user = client.users.me

          if json_output?
            output_item user
          else
            # Show basic user info
            output_item user, fields: %i[display_name email time_created], labels: {
              time_created: "Time Created"
            }

            # Show workspaces with roles
            if user.teams&.any?
              say ""
              say "Workspaces:", :cyan
              user.teams.each do |team|
                say "  #{team.team_name} (#{team.id}) - #{team.role}"
              end
            end
          end
        end
      end

      desc "accounts SUBCOMMAND", "Manage accounts"
      subcommand "accounts", Superthread::Cli::Accounts

      desc "workspaces SUBCOMMAND", "List and select workspaces"
      subcommand "workspaces", Superthread::Cli::Workspaces

      desc "members SUBCOMMAND", "Workspace member commands"
      subcommand "members", Superthread::Cli::Members

      desc "cards SUBCOMMAND", "Card management commands"
      subcommand "cards", Superthread::Cli::Cards

      desc "boards SUBCOMMAND", "Board and list management commands"
      subcommand "boards", Superthread::Cli::Boards

      desc "projects SUBCOMMAND", "Roadmap project (epic) commands"
      subcommand "projects", Superthread::Cli::Projects

      desc "spaces SUBCOMMAND", "Space management commands"
      subcommand "spaces", Superthread::Cli::Spaces

      desc "comments SUBCOMMAND", "Comment management commands"
      subcommand "comments", Superthread::Cli::Comments

      desc "replies SUBCOMMAND", "Comment reply commands"
      subcommand "replies", Superthread::Cli::Replies

      desc "lists SUBCOMMAND", "Board list (column) commands"
      subcommand "lists", Superthread::Cli::Lists

      desc "checklists SUBCOMMAND", "Card checklist commands"
      subcommand "checklists", Superthread::Cli::Checklists

      desc "pages SUBCOMMAND", "Page/documentation commands"
      subcommand "pages", Superthread::Cli::Pages

      desc "notes SUBCOMMAND", "Meeting notes commands"
      subcommand "notes", Superthread::Cli::Notes

      desc "sprints SUBCOMMAND", "Sprint commands"
      subcommand "sprints", Superthread::Cli::Sprints

      desc "search QUERY", "Search across workspace"
      subcommand "search", Superthread::Cli::Search

      desc "tags SUBCOMMAND", "Tag management commands"
      subcommand "tags", Superthread::Cli::Tags

      desc "activity", "Show recent activity across workspace"
      subcommand "activity", Superthread::Cli::Activity

      desc "completion SHELL", "Generate shell completion scripts"
      subcommand "completion", Superthread::Cli::Completion
    end
  end
end
