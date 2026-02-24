# frozen_string_literal: true

RSpec.describe Superthread::VersionChecker do
  let(:cache_dir) { Dir.mktmpdir }
  let(:cache_file) { File.join(cache_dir, "version_check.json") }

  before do
    allow(described_class).to receive(:cache_path).and_return(cache_file)
    ENV.delete("SUPERTHREAD_NO_UPDATE_CHECK")
  end

  after do
    FileUtils.rm_rf(cache_dir)
  end

  describe ".newer?" do
    it "returns true when given version is higher" do
      expect(described_class.newer?("99.0.0")).to be true
    end

    it "returns false when given version is the same" do
      expect(described_class.newer?(Superthread::VERSION)).to be false
    end

    it "returns false when given version is lower" do
      expect(described_class.newer?("0.0.1")).to be false
    end

    it "returns false for invalid version strings" do
      expect(described_class.newer?("not-a-version")).to be false
    end
  end

  describe ".disabled?" do
    it "returns false when env var is not set" do
      ENV.delete("SUPERTHREAD_NO_UPDATE_CHECK")
      expect(described_class.disabled?).to be false
    end

    it "returns true when env var is set" do
      ENV["SUPERTHREAD_NO_UPDATE_CHECK"] = "1"
      expect(described_class.disabled?).to be true
      ENV.delete("SUPERTHREAD_NO_UPDATE_CHECK")
    end
  end

  describe ".update_notice" do
    it "returns nil when no cache exists" do
      expect(described_class.update_notice).to be_nil
    end

    it "returns nil when disabled" do
      ENV["SUPERTHREAD_NO_UPDATE_CHECK"] = "1"
      expect(described_class.update_notice).to be_nil
      ENV.delete("SUPERTHREAD_NO_UPDATE_CHECK")
    end

    it "returns nil when cached version is not newer" do
      described_class.write_cache(Superthread::VERSION)
      expect(described_class.update_notice).to be_nil
    end

    it "returns a message when cached version is newer" do
      described_class.write_cache("99.0.0")
      notice = described_class.update_notice
      expect(notice).to include("Update available")
      expect(notice).to include("99.0.0")
      expect(notice).to include("brew upgrade superthread")
    end
  end

  describe ".check!" do
    it "returns nil when disabled" do
      ENV["SUPERTHREAD_NO_UPDATE_CHECK"] = "1"
      expect(described_class.check!).to be_nil
      ENV.delete("SUPERTHREAD_NO_UPDATE_CHECK")
    end

    it "fetches and caches the latest version" do
      stub_request(:get, Superthread::VersionChecker::RELEASES_URL)
        .to_return(status: 200, body: {tag_name: "v99.0.0"}.to_json,
          headers: {"Content-Type" => "application/json"})

      result = described_class.check!
      expect(result).to eq("99.0.0")
      expect(File.exist?(cache_file)).to be true

      cached = described_class.read_cache
      expect(cached[:latest_version]).to eq("99.0.0")
    end

    it "returns nil on network error" do
      stub_request(:get, Superthread::VersionChecker::RELEASES_URL)
        .to_raise(Faraday::ConnectionFailed)

      expect(described_class.check!).to be_nil
    end

    it "returns nil on non-200 response" do
      stub_request(:get, Superthread::VersionChecker::RELEASES_URL)
        .to_return(status: 404, body: "")

      expect(described_class.check!).to be_nil
    end

    it "strips leading v from tag name" do
      stub_request(:get, Superthread::VersionChecker::RELEASES_URL)
        .to_return(status: 200, body: {tag_name: "v1.2.3"}.to_json,
          headers: {"Content-Type" => "application/json"})

      expect(described_class.check!).to eq("1.2.3")
    end
  end

  describe ".check_if_stale!" do
    it "fetches when no cache exists" do
      stub_request(:get, Superthread::VersionChecker::RELEASES_URL)
        .to_return(status: 200, body: {tag_name: "v99.0.0"}.to_json,
          headers: {"Content-Type" => "application/json"})

      expect(described_class.check_if_stale!).to eq("99.0.0")
    end

    it "uses cache when fresh" do
      described_class.write_cache("88.0.0")

      # Should not make a network request
      expect(described_class.check_if_stale!).to eq("88.0.0")
    end

    it "re-fetches when cache is stale" do
      # Write cache with old timestamp
      FileUtils.mkdir_p(File.dirname(cache_file))
      File.write(cache_file, JSON.generate(
        latest_version: "1.0.0",
        checked_at: Time.now.to_i - 90_000
      ))

      stub_request(:get, Superthread::VersionChecker::RELEASES_URL)
        .to_return(status: 200, body: {tag_name: "v99.0.0"}.to_json,
          headers: {"Content-Type" => "application/json"})

      expect(described_class.check_if_stale!).to eq("99.0.0")
    end
  end

  describe ".read_cache / .write_cache" do
    it "round-trips data through cache" do
      described_class.write_cache("1.2.3")
      cached = described_class.read_cache

      expect(cached[:latest_version]).to eq("1.2.3")
      expect(cached[:checked_at]).to be_within(2).of(Time.now.to_i)
    end

    it "returns nil for missing cache" do
      expect(described_class.read_cache).to be_nil
    end

    it "returns nil for corrupt cache" do
      FileUtils.mkdir_p(File.dirname(cache_file))
      File.write(cache_file, "not json{{{")
      expect(described_class.read_cache).to be_nil
    end
  end
end
