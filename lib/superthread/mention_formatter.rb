# frozen_string_literal: true

require "cgi"

module Superthread
  # Converts {{@mentions}} in content to Superthread's HTML user-mention tags.
  #
  # Superthread allows user names with spaces, punctuation, and titles
  # (e.g., "John A. J. Smith the 3rd, Esq."), making traditional @mention
  # syntax unreliable. The {{@Name}} template syntax provides unambiguous
  # delimiters that handle any valid display name.
  #
  # Uses a three-pass algorithm:
  # 1. Escape protected mentions: `\{{@Name}}` -> placeholder
  # 2. Replace mentions: `{{@Name}}` -> `<user-mention>` HTML tag
  # 3. Restore escaped text: placeholder -> `{{@Name}}`
  #
  # @example Basic usage
  #   formatter = MentionFormatter.new(client, "ws-123")
  #   formatter.format("Hey {{@Steve Clarke}}, check this")
  #   # => 'Hey <user-mention data-type="mention" user-id="u123" ...></user-mention>, check this'
  #
  # @example Escaping
  #   formatter.format('Use \{{@Username}} syntax to mention users')
  #   # => "Use {{@Username}} syntax to mention users"
  class MentionFormatter
    # @return [Regexp] pattern matching `{{@Name}}` mention templates
    MENTION_PATTERN = /\{\{@([^}]+)\}\}/
    # @return [Regexp] pattern matching escaped `\{{@Name}}` mentions
    ESCAPE_PATTERN = /\\\{\{@([^}]+)\}\}/
    # @return [Regexp] pattern matching placeholders used during escape processing
    PLACEHOLDER_PATTERN = /___ESCAPED_MENTION_(.+?)___END___/

    # @param client [Superthread::Client] the API client for fetching members
    # @param workspace_id [String] the workspace to look up members in
    def initialize(client, workspace_id)
      @client = client
      @workspace_id = workspace_id
    end

    # Formats mention templates in content to HTML user-mention tags.
    #
    # @param content [String, nil] text that may contain {{@Name}} patterns
    # @return [String, nil] content with mentions converted to HTML tags
    def format(content)
      return content if content.nil? || !content.include?("{{@")

      member_map = build_member_map
      return content if member_map.nil?

      mention_time = Time.now.to_i

      # Pass 1: protect escaped mentions (store name only, not the {{@ }} delimiters)
      result = content.gsub(ESCAPE_PATTERN, '___ESCAPED_MENTION_\1___END___')

      # Pass 2: replace {{@Name}} with HTML tags
      result = result.gsub(MENTION_PATTERN) do |match|
        name = Regexp.last_match(1).strip
        member = member_map[name.downcase]

        if member
          safe_id = CGI.escapeHTML(member[:id])
          safe_name = CGI.escapeHTML(member[:name])
          '<user-mention data-type="mention" ' \
            "user-id=\"#{safe_id}\" " \
            "mention-time=\"#{mention_time}\" " \
            "user-value=\"#{safe_name}\" " \
            'denotation-char="@"></user-mention>'
        else
          match
        end
      end

      # Pass 3: restore escaped mentions as literal {{@Name}} text
      result.gsub(PLACEHOLDER_PATTERN, '{{@\1}}')
    end

    private

    # Fetches workspace members and builds a case-insensitive lookup map.
    #
    # @return [Hash{String => Hash}, nil] map of lowercase names to {id:, name:}, or nil on failure
    def build_member_map
      members = @client.users.members(@workspace_id)
      map = {}
      members.each do |member|
        next unless member.display_name

        map[member.display_name.downcase] = {
          id: member.user_identifier,
          name: member.display_name
        }
      end
      map
    rescue Superthread::Error
      nil
    end
  end
end
