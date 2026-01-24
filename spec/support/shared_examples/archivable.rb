# frozen_string_literal: true

# Shared examples for models that include Archivable concern.
#
# @example Usage in spec
#   RSpec.describe Superthread::Models::Board do
#     it_behaves_like "archivable" do
#       let(:model_class) { described_class }
#     end
#   end
#
RSpec.shared_examples "archivable" do
  describe "#archived?" do
    it "returns true when archived is truthy" do
      instance = model_class.from_response("archived" => true)
      expect(instance.archived?).to be true
    end

    it "returns true when archived is a hash (archived info)" do
      instance = model_class.from_response("archived" => {"user_id" => "user-1", "time_archived" => 123})
      expect(instance.archived?).to be true
    end

    it "returns false when archived is false" do
      instance = model_class.from_response("archived" => false)
      expect(instance.archived?).to be false
    end

    it "returns false when archived is nil" do
      instance = model_class.from_response("archived" => nil)
      expect(instance.archived?).to be false
    end

    it "returns false when archived is missing" do
      instance = model_class.from_response({})
      expect(instance.archived?).to be false
    end
  end
end
