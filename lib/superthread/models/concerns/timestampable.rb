# frozen_string_literal: true

require "active_support/concern"

module Superthread
  module Models
    module Concerns
      # Provides a DSL for defining timestamp accessor methods.
      #
      # Converts Unix timestamps (integers) to Ruby Time objects automatically.
      # Supports both auto-generated method names and explicit mappings.
      #
      # @example
      #   class Card < Superthread::Model
      #     include Concerns::Timestampable
      #
      #     attribute :time_created, Shale::Type::Integer
      #     attribute :time_updated, Shale::Type::Integer
      #     attribute :start_date, Shale::Type::Integer
      #
      #     timestamps :time_created, :time_updated
      #     timestamps start_date: :start_time, due_date: :due_time
      #   end
      #
      #   card.created_at  # => Time object
      #   card.start_time  # => Time object
      module Timestampable
        extend ActiveSupport::Concern

        class_methods do
          # Define timestamp accessor methods.
          #
          # With symbols, creates standard accessor names:
          # - time_created -> created_at
          # - time_updated -> updated_at
          # - start_date -> start_time
          #
          # With hash, creates custom accessor names (e.g., start_date: :start_time).
          #
          # @param fields [Array<Symbol>] attribute names to create accessors for
          # @param mappings [Hash{Symbol => Symbol}] explicit attribute to method name mappings
          # @return [void]
          def timestamps(*fields, **mappings)
            # Handle simple field names with auto-generated method names
            fields.each do |field|
              method_name = derive_method_name(field)
              define_timestamp_method(field, method_name)
            end

            # Handle explicit field => method mappings
            mappings.each do |field, method_name|
              define_timestamp_method(field, method_name)
            end
          end

          private

          # Derives a conventional method name from a timestamp field name.
          #
          # @param field [Symbol] the attribute name
          # @return [Symbol] the derived method name
          def derive_method_name(field)
            name = field.to_s
            if name.start_with?("time_")
              # time_created -> created_at, time_updated -> updated_at
              name.sub(/^time_/, "").concat("_at").to_sym
            elsif name.end_with?("_date")
              # start_date -> start_time, due_date -> due_time
              name.sub(/_date$/, "_time").to_sym
            else
              # fallback: field_at
              :"#{name}_at"
            end
          end

          # Defines an instance method that converts a Unix timestamp to Time.
          #
          # @param field [Symbol] the source attribute name
          # @param method_name [Symbol] the accessor method name to define
          # @return [void]
          def define_timestamp_method(field, method_name)
            define_method(method_name) do
              ts = send(field)
              (ts && ts != 0) ? Time.at(ts) : nil
            end
          end
        end
      end
    end
  end
end
