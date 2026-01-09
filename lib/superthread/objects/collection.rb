# frozen_string_literal: true

module Superthread
  module Objects
    # Represents a collection of objects returned from list endpoints.
    # Wraps arrays with additional metadata and convenience methods.
    #
    # @example
    #   cards = client.cards.assigned(workspace_id, user_id: user_id)
    #   cards.each { |card| puts card.title }
    #   cards.count        # => 5
    #   cards.empty?       # => false
    #   cards.to_a         # => [#<Superthread::Objects::Card ...>, ...]
    #
    class Collection
      include Enumerable

      # @return [Array<Superthread::Object>] The items in the collection
      attr_reader :items

      # @return [Hash] Raw response data
      attr_reader :data

      # Creates a new collection from API response data.
      #
      # @param data [Hash] The raw API response
      # @param key [Symbol, String] The key containing the items array
      # @param item_class [Class] The class to use for items (optional, auto-detected)
      def initialize(data, key: nil, item_class: nil)
        @data = data.is_a?(Hash) ? data.transform_keys(&:to_sym) : {}
        @item_class = item_class

        # Extract items from the response
        items_data = extract_items(key)
        @items = items_data.map { |item| wrap_item(item) }
      end

      # Factory method for constructing collections from API responses.
      #
      # @param data [Hash, Array] The API response
      # @param key [Symbol, String, nil] The key containing items (auto-detected if nil)
      # @param item_class [Class, nil] The class for items
      # @return [Superthread::Objects::Collection]
      def self.from_response(data, key: nil, item_class: nil)
        # If the response is already an array, wrap it
        if data.is_a?(Array)
          new({ items: data }, key: :items, item_class: item_class)
        else
          new(data, key: key, item_class: item_class)
        end
      end

      # Iterate over items.
      #
      # @yield [item] Each item in the collection
      def each(&block)
        @items.each(&block)
      end

      # Number of items.
      #
      # @return [Integer] Item count
      def count
        @items.count
      end
      alias size count
      alias length count

      # Check if empty.
      #
      # @return [Boolean] True if no items
      def empty?
        @items.empty?
      end

      # First item.
      #
      # @return [Superthread::Object, nil] First item or nil
      def first
        @items.first
      end

      # Last item.
      #
      # @return [Superthread::Object, nil] Last item or nil
      def last
        @items.last
      end

      # Access by index.
      #
      # @param index [Integer] The index
      # @return [Superthread::Object, nil] Item at index
      def [](index)
        @items[index]
      end

      # Convert to array.
      #
      # @return [Array<Superthread::Object>] Array of items
      def to_a
        @items.dup
      end
      alias to_ary to_a

      # Convert to array of hashes.
      #
      # @return [Array<Hash>] Array of hash representations
      def to_h
        @items.map(&:to_h)
      end

      # Get raw response metadata (everything except items).
      #
      # @return [Hash] Metadata
      def metadata
        @data.reject { |k, _| items_keys.include?(k) }
      end

      private

      # Common keys that contain item arrays
      ITEMS_KEYS = %i[items cards boards lists users projects spaces sprints
                      pages notes comments tags members results data].freeze

      def items_keys
        ITEMS_KEYS
      end

      def extract_items(key)
        if key
          @data[key.to_sym] || []
        else
          # Auto-detect items key
          ITEMS_KEYS.each do |k|
            return @data[k] if @data[k].is_a?(Array)
          end
          # If nothing found, check if the response itself has a single array value
          @data.values.find { |v| v.is_a?(Array) } || []
        end
      end

      def wrap_item(item)
        return item unless item.is_a?(Hash)

        if @item_class
          @item_class.new(item)
        else
          Superthread::Object.construct_from(item)
        end
      end
    end
  end
end
