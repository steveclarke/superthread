# frozen_string_literal: true

module Superthread
  module Cli
    class Main < Base
      desc 'version', 'Show version'
      def version
        puts "superthread #{Superthread::VERSION}"
      end

      desc 'config SUBCOMMAND', 'Manage configuration'
      subcommand 'config', Superthread::Cli::Config

      desc 'workspaces SUBCOMMAND', 'List and select workspaces'
      subcommand 'workspaces', Superthread::Cli::Workspaces

      desc 'users SUBCOMMAND', 'User and workspace member commands'
      subcommand 'users', Superthread::Cli::Users

      desc 'cards SUBCOMMAND', 'Card management commands'
      subcommand 'cards', Superthread::Cli::Cards

      desc 'boards SUBCOMMAND', 'Board and list management commands'
      subcommand 'boards', Superthread::Cli::Boards

      desc 'projects SUBCOMMAND', 'Roadmap project (epic) commands'
      subcommand 'projects', Superthread::Cli::Projects

      desc 'spaces SUBCOMMAND', 'Space management commands'
      subcommand 'spaces', Superthread::Cli::Spaces

      desc 'comments SUBCOMMAND', 'Comment management commands'
      subcommand 'comments', Superthread::Cli::Comments

      desc 'pages SUBCOMMAND', 'Page/documentation commands'
      subcommand 'pages', Superthread::Cli::Pages

      desc 'notes SUBCOMMAND', 'Meeting notes commands'
      subcommand 'notes', Superthread::Cli::Notes

      desc 'sprints SUBCOMMAND', 'Sprint commands'
      subcommand 'sprints', Superthread::Cli::Sprints

      desc 'search QUERY', 'Search across workspace'
      subcommand 'search', Superthread::Cli::Search

      desc 'tags SUBCOMMAND', 'Tag management commands'
      subcommand 'tags', Superthread::Cli::Tags
    end
  end
end
