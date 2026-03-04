# frozen_string_literal: true

# Shared examples for models that support hash-like access.
#
# @example Usage in spec
#   RSpec.describe Superthread::Models::Board do
#     it_behaves_like "hash accessible" do
#       let(:hash_symbol_key) { :title }
#       let(:hash_symbol_value) { "Sprint Board" }
#       let(:hash_string_key) { "team_id" }
#       let(:hash_string_value) { "team-456" }
#     end
#   end
#
RSpec.shared_examples "hash accessible" do
  describe "hash-like access" do
    it "supports bracket access" do
      expect(subject[hash_symbol_key]).to eq(hash_symbol_value)
      expect(subject[hash_string_key]).to eq(hash_string_value)
    end

    it "supports key? check" do
      expect(subject.key?(hash_symbol_key)).to be true
      expect(subject.key?(:nonexistent)).to be false
    end
  end
end
