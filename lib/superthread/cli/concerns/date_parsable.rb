# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Cli
    module Concerns
      # Provides date parsing utilities for CLI commands.
      # Parses natural language dates into Unix timestamps for API filtering.
      #
      # @example
      #   class Cards < Base
      #     include Concerns::DateParsable
      #
      #     def list
      #       since_timestamp = parse_date(options[:since])
      #       # Filter cards by since_timestamp...
      #     end
      #   end
      #
      module DateParsable
        extend ActiveSupport::Concern

        SECONDS_PER_DAY = 86_400
        SECONDS_PER_WEEK = 604_800

        # Parse a date string into a Unix timestamp (seconds).
        # Supports various natural language formats.
        #
        # @param date_string [String, nil] Date expression to parse
        # @return [Integer, nil] Unix timestamp (seconds), or nil if no date provided
        # @raise [Thor::Error] If date string is invalid or unparseable
        #
        # @example Natural language dates
        #   parse_date("today")           # => Start of today
        #   parse_date("yesterday")       # => Start of yesterday
        #   parse_date("friday")          # => Last Friday (or this Friday if today is earlier)
        #   parse_date("last friday")     # => Last Friday
        #   parse_date("monday")          # => Last Monday
        #   parse_date("3 days ago")      # => 3 days ago
        #   parse_date("1 week ago")      # => 7 days ago
        #   parse_date("2 weeks ago")     # => 14 days ago
        #   parse_date("last week")       # => Start of last week
        #   parse_date("this week")       # => Start of this week
        #   parse_date("2026-01-20")      # => Specific date
        #
        def parse_date(date_string)
          return nil if date_string.nil? || date_string.empty?

          normalized = date_string.to_s.strip.downcase

          time = case normalized
          when "today", "now"
            beginning_of_day(Date.today)
          when "yesterday"
            beginning_of_day(Date.today - 1)
          when "this week"
            beginning_of_week(Date.today)
          when "last week"
            beginning_of_week(Date.today - 7)
          when /\A(\d+)\s+days?\s+ago\z/
            beginning_of_day(Date.today - Integer(::Regexp.last_match(1)))
          when /\A(\d+)\s+weeks?\s+ago\z/
            beginning_of_day(Date.today - (Integer(::Regexp.last_match(1)) * 7))
          when /\A(\d+)\s+months?\s+ago\z/
            beginning_of_day(Date.today << Integer(::Regexp.last_match(1)))
          when /\Alast\s+(#{day_names_pattern})\z/
            parse_weekday(::Regexp.last_match(1), force_past: true)
          when /\A(#{day_names_pattern})\z/
            parse_weekday(::Regexp.last_match(1))
          else
            # Try parsing as a date (YYYY-MM-DD, MM/DD/YYYY, etc.)
            parse_explicit_date(date_string)
          end

          time&.to_i
        rescue ArgumentError, TypeError => e
          raise Thor::Error, "Invalid date: '#{date_string}'. #{e.message}"
        end

        # Parse a date string into a Time object at end of day.
        # Useful for "until" or "before" filters.
        #
        # @param date_string [String, nil] Date expression to parse
        # @return [Integer, nil] Unix timestamp at end of day, or nil
        #
        def parse_date_end(date_string)
          timestamp = parse_date(date_string)
          return nil unless timestamp

          # Add 23:59:59 to get end of day
          timestamp + SECONDS_PER_DAY - 1
        end

        # Filter a collection of items by timestamp field.
        # Used for client-side filtering when API doesn't support date filters.
        #
        # @param items [Enumerable] Collection to filter
        # @param field [Symbol] Timestamp field name (e.g., :time_created, :time_updated)
        # @param since [Integer, nil] Minimum timestamp (inclusive)
        # @param until_time [Integer, nil] Maximum timestamp (inclusive)
        # @return [Array] Filtered items
        #
        def filter_by_date(items, field:, since: nil, until_time: nil)
          items.select do |item|
            ts = item.send(field)
            next false if ts.nil?

            # Handle milliseconds vs seconds
            ts /= 1000 if ts > 9_999_999_999

            (since.nil? || ts >= since) && (until_time.nil? || ts <= until_time)
          end
        end

        private

        # Convert Date to Time at beginning of day (midnight).
        def beginning_of_day(date)
          Time.new(date.year, date.month, date.day, 0, 0, 0)
        end

        # Get the beginning of the week for a date (Monday).
        def beginning_of_week(date)
          # wday: 0=Sunday, 1=Monday, ... 6=Saturday
          # We want Monday as start of week
          days_since_monday = (date.wday - 1) % 7
          beginning_of_day(date - days_since_monday)
        end

        # Pattern matching day names (full and abbreviated).
        def day_names_pattern
          "sunday|sun|monday|mon|tuesday|tue|tues|wednesday|wed|thursday|thu|thurs|friday|fri|saturday|sat"
        end

        # Parse a weekday name into a Time object.
        #
        # @param day_name [String] Day name (e.g., "friday", "mon")
        # @param force_past [Boolean] Always return a date in the past
        # @return [Time] Start of that day
        #
        def parse_weekday(day_name, force_past: false)
          target_wday = weekday_number(day_name)
          today = Date.today
          current_wday = today.wday

          # Calculate days back to the target weekday
          if force_past || target_wday >= current_wday
            # Need to go to last week's occurrence
            days_back = (current_wday - target_wday + 7) % 7
            days_back = 7 if days_back == 0 && force_past
          else
            # Target day is earlier this week
            days_back = current_wday - target_wday
          end

          beginning_of_day(today - days_back)
        end

        # Convert day name to weekday number (0=Sunday, 6=Saturday).
        def weekday_number(day_name)
          case day_name.downcase
          when "sunday", "sun" then 0
          when "monday", "mon" then 1
          when "tuesday", "tue", "tues" then 2
          when "wednesday", "wed" then 3
          when "thursday", "thu", "thurs" then 4
          when "friday", "fri" then 5
          when "saturday", "sat" then 6
          else
            raise ArgumentError, "Unknown day: #{day_name}"
          end
        end

        # Parse an explicit date string (YYYY-MM-DD, etc.).
        def parse_explicit_date(date_string)
          beginning_of_day(Date.parse(date_string))
        rescue ArgumentError
          raise Thor::Error,
            "Could not parse date: '#{date_string}'. " \
            "Try formats like '2026-01-20', 'friday', '3 days ago', or 'last week'."
        end
      end
    end
  end
end
