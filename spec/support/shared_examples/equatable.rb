# frozen_string_literal: true

# Shared examples for models that support equality comparison.
#
# @example Usage in spec
#   RSpec.describe Superthread::Models::Board do
#     it_behaves_like "equatable" do
#       let(:model_class) { described_class }
#       let(:model_data) { board_data }
#     end
#   end
#
RSpec.shared_examples "equatable" do
  describe "#==" do
    it "compares by attributes" do
      instance2 = model_class.from_response(model_data)
      expect(subject).to eq(instance2)
    end

    it "returns false for different instances" do
      instance2 = model_class.from_response(model_data.merge("id" => "different"))
      expect(subject).not_to eq(instance2)
    end
  end
end
