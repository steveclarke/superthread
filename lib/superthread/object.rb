# frozen_string_literal: true

module Superthread
  # Base class for all Superthread API response objects.
  # Provides hash-like access, dot notation via method_missing, and conversion to Hash.
  #
  # Inspired by Stripe's StripeObject pattern - allows both:
  #   card.title        # dot notation
  #   card[:title]      # symbol key access
  #   card["title"]     # string key access
  #   card.to_h         # convert to plain hash
  #
  # @example
  #   card = client.cards.find(workspace_id, card_id)
  #   card.title              # => "My Card"
  #   card[:title]            # => "My Card"
  #   card.members.first.role # => "admin"
  #   card.to_h               # => { id: "123", title: "My Card", ... }
  #
  class Object
    include Enumerable

    # @return [Hash] The raw data from the API response
    attr_reader :data

    # Creates a new object from a Hash or another SuperthreadObject.
    #
    # @param data [Hash, Superthread::Object] The data to wrap
    def initialize(data = {})
      @data = case data
              when Hash
                data.transform_keys(&:to_sym)
              when Superthread::Object
                data.data.dup
              else
                {}
              end
    end

    # Factory method to construct the appropriate typed object from API response data.
    # Uses the "type" field in the response to determine the class.
    #
    # @param data [Hash, Array, nil] The API response data
    # @return [Superthread::Object, Array, nil] The constructed object(s)
    def self.construct_from(data)
      case data
      when Array
        data.map { |item| construct_from(item) }
      when Hash
        klass = object_class_for(data)
        klass.new(data)
      else
        data
      end
    end

    # Determines the appropriate class for the given data based on the "type" field.
    #
    # @param data [Hash] The data hash
    # @return [Class] The class to use for construction
    def self.object_class_for(data)
      type = data[:type] || data['type']
      @object_types.fetch(type, Superthread::Object)
    end

    # Registry mapping API "type" values to Ruby classes.
    # Subclasses register themselves here.
    # Note: This hash is intentionally mutable for dynamic registration.
    @object_types = {}

    class << self
      attr_reader :object_types
    end

    # Registers a subclass for a given type name.
    # Called automatically when OBJECT_NAME is defined on a subclass.
    #
    # @param type_name [String] The API type name
    # @param klass [Class] The class to register
    def self.register_type(type_name, klass)
      @object_types[type_name] = klass
    end

    # Hook called when a subclass is defined.
    # Automatically registers the subclass if it defines OBJECT_NAME.
    def self.inherited(subclass)
      super
      subclass.instance_eval do
        def self.object_name
          const_defined?(:OBJECT_NAME, false) ? const_get(:OBJECT_NAME) : nil
        end
      end
    end

    # Access a value by key (symbol or string).
    #
    # @param key [Symbol, String] The key to access
    # @return [Object] The value, wrapped in a SuperthreadObject if it's a Hash
    def [](key)
      value = @data[key.to_sym]
      wrap_value(value)
    end

    # Set a value by key.
    #
    # @param key [Symbol, String] The key to set
    # @param value [Object] The value to set
    def []=(key, value)
      @data[key.to_sym] = value
    end

    # Iterate over key-value pairs.
    #
    # @yield [key, value] Each key-value pair
    def each(&block)
      @data.each do |key, value|
        block.call(key, wrap_value(value))
      end
    end

    # Returns all keys.
    #
    # @return [Array<Symbol>] The keys
    def keys
      @data.keys
    end

    # Returns all values (wrapped).
    #
    # @return [Array] The values
    def values
      @data.values.map { |v| wrap_value(v) }
    end

    # Check if a key exists.
    #
    # @param key [Symbol, String] The key to check
    # @return [Boolean] True if the key exists
    def key?(key)
      @data.key?(key.to_sym)
    end
    alias has_key? key?

    # Convert to a plain Hash (deep conversion).
    #
    # @return [Hash] A plain hash representation
    def to_h
      @data.transform_values do |value|
        case value
        when Superthread::Object
          value.to_h
        when Array
          value.map { |v| v.respond_to?(:to_h) ? v.to_h : v }
        when Hash
          value.transform_values { |v| v.respond_to?(:to_h) ? v.to_h : v }
        else
          value
        end
      end
    end
    alias to_hash to_h

    # Convert to JSON string.
    #
    # @param args [Array] Arguments passed to JSON.generate
    # @return [String] JSON representation
    def to_json(*args)
      to_h.to_json(*args)
    end

    # Check equality based on data.
    #
    # @param other [Object] The object to compare
    # @return [Boolean] True if equal
    def ==(other)
      case other
      when Superthread::Object
        @data == other.data
      when Hash
        @data == other.transform_keys(&:to_sym)
      else
        false
      end
    end
    alias eql? ==

    # Hash code for use in Hash keys.
    #
    # @return [Integer] Hash code
    def hash
      @data.hash
    end

    # String representation for debugging.
    #
    # @return [String] Debug representation
    def inspect
      "#<#{self.class.name} #{@data.inspect}>"
    end

    # Pretty string representation.
    #
    # @return [String] String representation
    def to_s
      inspect
    end

    # Check if the object has a given attribute.
    # Supports predicate methods like `archived?`.
    #
    # @param method_name [Symbol] The method name
    # @param include_private [Boolean] Whether to include private methods
    # @return [Boolean] True if the method exists
    def respond_to_missing?(method_name, include_private = false)
      name = method_name.to_s
      if name.end_with?('=')
        true
      elsif name.end_with?('?')
        @data.key?(name.chomp('?').to_sym)
      else
        @data.key?(name.to_sym) || super
      end
    end

    private

    # Dynamic attribute access via method_missing.
    # Supports:
    #   - Getters: card.title
    #   - Setters: card.title = "New Title"
    #   - Predicates: card.archived?
    #
    def method_missing(method_name, *args)
      name = method_name.to_s

      if name.end_with?('=')
        # Setter: card.title = "New Title"
        key = name.chomp('=').to_sym
        @data[key] = args.first
      elsif name.end_with?('?')
        # Predicate: card.archived?
        key = name.chomp('?').to_sym
        !!@data[key]
      elsif @data.key?(name.to_sym)
        # Getter: card.title
        wrap_value(@data[name.to_sym])
      else
        super
      end
    end

    # Wraps values in SuperthreadObject instances for nested access.
    # Arrays of Hashes become Arrays of SuperthreadObjects.
    #
    # @param value [Object] The value to wrap
    # @return [Object] The wrapped value
    def wrap_value(value)
      case value
      when Hash
        Superthread::Object.construct_from(value)
      when Array
        value.map { |v| wrap_value(v) }
      else
        value
      end
    end
  end
end
