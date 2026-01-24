# frozen_string_literal: true

# Shared examples for models that include Timestampable concern.
#
# @example Usage in spec
#   RSpec.describe Superthread::Models::Card do
#     it_behaves_like "timestampable" do
#       let(:model_class) { described_class }
#       let(:timestamp_mappings) do
#         {
#           time_created: :created_at,
#           time_updated: :updated_at,
#           start_date: :start_time,
#           due_date: :due_time
#         }
#       end
#     end
#   end
#
RSpec.shared_examples "timestampable" do
  let(:sample_timestamp) { 1_705_312_200 } # 2024-01-15 10:30:00 UTC

  describe "timestamp accessors" do
    it "converts timestamps to Time objects" do
      timestamp_mappings.each do |raw_field, accessor_method|
        instance = model_class.from_response(raw_field.to_s => sample_timestamp)
        expect(instance.send(accessor_method)).to be_a(Time),
          "Expected #{accessor_method} to return Time, got #{instance.send(accessor_method).class}"
      end
    end

    it "returns nil when timestamp is nil" do
      timestamp_mappings.each do |raw_field, accessor_method|
        instance = model_class.from_response(raw_field.to_s => nil)
        expect(instance.send(accessor_method)).to be_nil,
          "Expected #{accessor_method} to return nil for nil timestamp"
      end
    end

    it "returns nil when timestamp is zero" do
      timestamp_mappings.each do |raw_field, accessor_method|
        instance = model_class.from_response(raw_field.to_s => 0)
        expect(instance.send(accessor_method)).to be_nil,
          "Expected #{accessor_method} to return nil for zero timestamp"
      end
    end

    it "returns nil when timestamp is missing" do
      instance = model_class.from_response({})
      timestamp_mappings.each do |_raw_field, accessor_method|
        expect(instance.send(accessor_method)).to be_nil,
          "Expected #{accessor_method} to return nil for missing timestamp"
      end
    end
  end
end
