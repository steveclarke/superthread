# frozen_string_literal: true

module Superthread
  # Container classes for API response wrappers.
  module Objects
    # Represents a collection of objects returned from list endpoints.
    # Wraps arrays with additional metadata and convenience methods.
    #
    # @example
    #   cards = client.cards.assigned(workspace_id, user_id: user_id)
    #   cards.each { |card| puts card.title }
    #   cards.count        # => 5
    #   cards.empty?       # => false
    #   cards.to_a         # => [#<Superthread::Models::Card ...>, ...]
    class Collection
      include Enumerable

      # @return [Array<Superthread::Object, Superthread::Model>] the items in the collection
      attr_reader :items

      # @return [Hash{Symbol => Object}] raw response data
      attr_reader :data

      # Creates a new collection from API response data.
      #
      # @param data [Hash{Symbol => Object}] the raw API response
      # @param key [Symbol, String, nil] the key containing the items array (auto-detected if nil)
      # @param item_class [Class, nil] the class to use for items (auto-detected if nil)
      def initialize(data, key: nil, item_class: nil)
        @data = data.is_a?(Hash) ? data.transform_keys(&:to_sym) : {}
        @item_class = item_class

        # Extract items from the response
        items_data = extract_items(key)
        @items = items_data.map { |item| wrap_item(item) }
      end

      # Constructs a collection from an API response.
      #
      # @param data [Hash{Symbol => Object}, Array<Hash>] the API response
      # @param key [Symbol, String, nil] the key containing items (auto-detected if nil)
      # @param item_class [Class, nil] the class for items (auto-detected if nil)
      # @return [Superthread::Objects::Collection] the constructed collection
      def self.from_response(data, key: nil, item_class: nil)
        # If the response is already an array, wrap it
        if data.is_a?(Array)
          new({items: data}, key: :items, item_class: item_class)
        else
          new(data, key: key, item_class: item_class)
        end
      end

      # Iterates over items in the collection.
      #
      # @param block [Proc] receives each item in the collection
      # @yieldparam item [Superthread::Object, Superthread::Model] an item
      # @return [Enumerator] if no block given
      def each(&block)
        @items.each(&block)
      end

      # Returns the number of items in the collection.
      #
      # @return [Integer] item count
      def count
        @items.count
      end
      alias_method :size, :count
      alias_method :length, :count

      # Checks if the collection is empty.
      #
      # @return [Boolean] true if no items
      def empty?
        @items.empty?
      end

      # Returns the first item.
      #
      # @return [Superthread::Object, Superthread::Model, nil] first item or nil if empty
      def first
        @items.first
      end

      # Returns the last item.
      #
      # @return [Superthread::Object, Superthread::Model, nil] last item or nil if empty
      def last
        @items.last
      end

      # Accesses an item by index.
      #
      # @param index [Integer] the zero-based index
      # @return [Superthread::Object, Superthread::Model, nil] item at index or nil if out of bounds
      def [](index)
        @items[index]
      end

      # Converts the collection to an array.
      #
      # @return [Array<Superthread::Object, Superthread::Model>] copy of items array
      def to_a
        @items.dup
      end
      alias_method :to_ary, :to_a

      # Converts the collection to an array of hashes.
      #
      # @return [Array<Hash{Symbol => Object}>] array of hash representations
      def to_h
        @items.map(&:to_h)
      end

      # Returns raw response metadata (everything except items).
      #
      # @return [Hash{Symbol => Object}] metadata from the API response
      def metadata
        @data.except(*items_keys)
      end

      private

      # Common keys that contain item arrays in API responses.
      ITEMS_KEYS = %i[items cards boards lists users projects spaces sprints
        pages notes comments tags members results data].freeze

      # Returns the list of common item keys.
      #
      # @return [Array<Symbol>] keys that typically contain item arrays
      def items_keys
        ITEMS_KEYS
      end

      # Extracts items array from the response data.
      #
      # @param key [Symbol, String, nil] the key to extract, or nil to auto-detect
      # @return [Array<Hash>] the extracted items array
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

      # Wraps a hash item in the appropriate object class.
      #
      # @param item [Hash, Object] the item to wrap
      # @return [Superthread::Object, Superthread::Model] the wrapped item
      def wrap_item(item)
        return item unless item.is_a?(Hash)

        if @item_class
          if shale_model?(@item_class)
            @item_class.from_response(item)
          else
            @item_class.new(item)
          end
        else
          Superthread::Object.construct_from(item)
        end
      end

      # Checks if a class is a Shale model.
      #
      # @param klass [Class] the class to check
      # @return [Boolean] true if the class is a Shale model
      def shale_model?(klass)
        klass.respond_to?(:shale_model?) && klass.shale_model?
      end
    end
  end
end
