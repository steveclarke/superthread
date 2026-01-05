# frozen_string_literal: true

RSpec.describe Superthread::Resources::Base do
  let(:connection) { instance_double(Superthread::Connection) }
  let(:resource) { described_class.new(connection) }

  describe "#safe_id" do
    it "returns valid IDs unchanged" do
      expect(resource.send(:safe_id, "card_id", "crd_abc123")).to eq("crd_abc123")
    end

    it "strips whitespace" do
      expect(resource.send(:safe_id, "card_id", "  crd_abc123  ")).to eq("crd_abc123")
    end

    it "raises error for nil ID" do
      expect { resource.send(:safe_id, "card_id", nil) }
        .to raise_error(Superthread::PathValidationError, /card_id must be a non-empty string/)
    end

    it "raises error for empty ID" do
      expect { resource.send(:safe_id, "card_id", "") }
        .to raise_error(Superthread::PathValidationError, /card_id must be a non-empty string/)
    end

    it "sanitizes path traversal attempts" do
      expect(resource.send(:safe_id, "card_id", "../etc/passwd")).to eq("etcpasswd")
    end

    it "sanitizes slashes" do
      expect(resource.send(:safe_id, "card_id", "crd/abc")).to eq("crdabc")
    end

    it "sanitizes backslashes" do
      expect(resource.send(:safe_id, "card_id", "crd\\abc")).to eq("crdabc")
    end

    it "raises error when only invalid characters" do
      expect { resource.send(:safe_id, "card_id", "///") }
        .to raise_error(Superthread::PathValidationError, /must contain only letters/)
    end
  end

  describe "#build_params" do
    it "filters out nil values" do
      result = resource.send(:build_params, name: "test", color: nil, size: "large")
      expect(result).to eq(name: "test", size: "large")
    end

    it "keeps false values" do
      result = resource.send(:build_params, name: "test", archived: false)
      expect(result).to eq(name: "test", archived: false)
    end

    it "keeps empty strings" do
      result = resource.send(:build_params, name: "", title: "test")
      expect(result).to eq(name: "", title: "test")
    end

    it "returns empty hash when all values are nil" do
      result = resource.send(:build_params, name: nil, color: nil)
      expect(result).to eq({})
    end
  end
end
