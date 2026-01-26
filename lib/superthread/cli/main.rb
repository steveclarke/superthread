# frozen_string_literal: true

module Superthread
  module Cli
    class Main < Base
      desc "version", "Show version"
      def version
        puts "superthread #{Superthread::VERSION}"
      end

      desc "setup", "Interactive setup wizard"
      def setup
        Superthread::Cli::Setup.execute
      end

      desc "config SUBCOMMAND", "Manage configuration"
      subcommand "config", Superthread::Cli::Config

      desc "me", "Show current user account info"
      def me
        handle_error do
          user = client.users.me

          if json_output?
            output_item user
          else
            # Show basic user info
            output_item user, fields: %i[display_name email time_created]

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
