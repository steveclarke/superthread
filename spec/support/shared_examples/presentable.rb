# frozen_string_literal: true

# Shared examples for models that include Presentable concern.
#
# @example Usage in spec
#   RSpec.describe Superthread::Models::Card do
#     it_behaves_like "presentable" do
#       let(:model_class) { described_class }
#       let(:presentation_attribute) { :title }
#       let(:presentation_value) { "My Card Title" }
#     end
#   end
#
RSpec.shared_examples "presentable" do
  describe "#to_s" do
    it "returns the presentation attribute value" do
      instance = model_class.from_response(presentation_attribute.to_s => presentation_value)
      expect(instance.to_s).to eq(presentation_value)
    end

    it "returns empty string when presentation attribute is nil" do
      instance = model_class.from_response(presentation_attribute.to_s => nil)
      expect(instance.to_s).to eq("")
    end

    it "returns empty string when presentation attribute is missing" do
      instance = model_class.from_response({})
      expect(instance.to_s).to eq("")
    end
  end
end
