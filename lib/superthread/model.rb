# frozen_string_literal: true

require "shale"

module Superthread
  # Base class for all Shale-based API response models.
  # Provides a consistent interface compatible with existing code patterns.
  #
  # @example Defining a model
  #   class Card < Superthread::Model
  #     attribute :id, Shale::Type::String
  #     attribute :title, Shale::Type::String
  #     attribute :priority, Shale::Type::Integer
  #     attribute :members, Member, collection: true
  #
  #     def priority_name
  #       { 1 => 'urgent', 2 => 'high', 3 => 'medium', 4 => 'low' }[priority]
  #     end
  #   end
  #
  # @example Using a model
  #   card = Card.from_hash(json_data)
  #   card.title          # => "My Card"
  #   card.priority       # => 1
  #   card.priority_name  # => "urgent"
  #   card.to_h           # => { id: "123", title: "My Card", ... }
  #
  class Model < Shale::Mapper
    class << self
      # Check if this is a Shale-based model.
      # Used by the client to determine deserialization method.
      #
      # @return [Boolean] Always true for Model subclasses
      def shale_model?
        true
      end

      # Construct a model from a hash (API response).
      # This is the primary factory method used by the client.
      #
      # @param data [Hash] The hash data from the API
      # @return [Model] The constructed model instance
      def from_response(data)
        return nil if data.nil?

        # Shale's from_hash handles the conversion
        from_hash(data.transform_keys(&:to_s))
      end

      # Construct a collection of models from an array of hashes.
      #
      # @param items [Array<Hash>] Array of hash data
      # @return [Array<Model>] Array of model instances
      def from_response_array(items)
        return [] if items.nil?

        items.map { |item| from_response(item) }
      end
    end

    # Convert to a hash with symbol keys.
    # Provides compatibility with existing code expecting symbol keys.
    # Uses Shale's to_hash internally, then symbolizes keys.
    #
    # @return [Hash] Hash representation with symbol keys
    def to_h
      deep_symbolize_keys(to_hash)
    end

    private

    # Recursively symbolize hash keys.
    #
    # @param obj [Object] Object to process
    # @return [Object] Object with symbolized keys
    def deep_symbolize_keys(obj)
      case obj
      when Hash
        obj.transform_keys(&:to_sym).transform_values { |v| deep_symbolize_keys(v) }
      when Array
        obj.map { |v| deep_symbolize_keys(v) }
      else
        obj
      end
    end

    public

    # Access attribute by key (symbol or string).
    # Provides hash-like access for compatibility.
    #
    # @param key [Symbol, String] The attribute name
    # @return [Object] The attribute value
    def [](key)
      send(key.to_sym)
    rescue NoMethodError
      nil
    end

    # Check if a key/attribute exists.
    #
    # @param key [Symbol, String] The attribute name
    # @return [Boolean] True if the attribute is defined
    def key?(key)
      respond_to?(key.to_sym)
    end
    alias_method :has_key?, :key?

    # String representation for debugging.
    #
    # @return [String] Debug representation
    def inspect
      attrs = self.class.attributes.keys.map do |attr|
        value = send(attr)
        "#{attr}: #{value.inspect}"
      end.join(", ")
      "#<#{self.class.name} #{attrs}>"
    end

    # Comparison by attribute values.
    #
    # @param other [Object] Object to compare
    # @return [Boolean] True if equal
    def ==(other)
      return false unless other.is_a?(self.class)

      self.class.attributes.keys.all? do |attr|
        send(attr) == other.send(attr)
      end
    end
    alias_method :eql?, :==

    # Hash code based on attributes.
    #
    # @return [Integer] Hash code
    def hash
      to_h.hash
    end

    protected

    # Helper to convert Unix milliseconds to Time.
    # Use in helper methods for timestamp fields.
    #
    # @param ms [Integer, nil] Unix timestamp in milliseconds
    # @return [Time, nil] Time object or nil
    def ms_to_time(ms)
      ms && Time.at(ms / 1000.0)
    end
  end
end
