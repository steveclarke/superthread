# frozen_string_literal: true

require "spec_helper"
require "ostruct"

RSpec.describe Superthread::Cli::Concerns::DateParsable do
  let(:test_class) do
    Class.new do
      include Superthread::Cli::Concerns::DateParsable
    end
  end

  let(:instance) { test_class.new }

  describe "#parse_date" do
    # Use a fixed reference date for testing: Monday, January 20, 2025
    let(:reference_date) { Date.new(2025, 1, 20) }
    let(:reference_time) { Time.new(2025, 1, 20, 12, 0, 0) }

    before do
      allow(Date).to receive(:today).and_return(reference_date)
      allow(Time).to receive(:now).and_return(reference_time)
    end

    it "returns nil for nil input" do
      expect(instance.parse_date(nil)).to be_nil
    end

    it "returns nil for empty string" do
      expect(instance.parse_date("")).to be_nil
    end

    describe "relative dates" do
      it "parses 'today'" do
        result = instance.parse_date("today")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 20, 0, 0, 0))
      end

      it "parses 'now'" do
        result = instance.parse_date("now")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 20, 0, 0, 0))
      end

      it "parses 'yesterday'" do
        result = instance.parse_date("yesterday")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 19, 0, 0, 0))
      end

      it "parses 'this week'" do
        result = instance.parse_date("this week")
        # Week starts Monday in ActiveSupport
        expect(Time.at(result)).to eq(Time.new(2025, 1, 20, 0, 0, 0))
      end

      it "parses 'last week'" do
        result = instance.parse_date("last week")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 13, 0, 0, 0))
      end
    end

    describe "N days/weeks/months ago" do
      it "parses '3 days ago'" do
        result = instance.parse_date("3 days ago")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 17, 0, 0, 0))
      end

      it "parses '1 day ago'" do
        result = instance.parse_date("1 day ago")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 19, 0, 0, 0))
      end

      it "parses '2 weeks ago'" do
        result = instance.parse_date("2 weeks ago")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 6, 0, 0, 0))
      end

      it "parses '1 month ago'" do
        result = instance.parse_date("1 month ago")
        expect(Time.at(result)).to eq(Time.new(2024, 12, 20, 0, 0, 0))
      end
    end

    describe "weekday names" do
      # Today is Monday, January 20, 2025

      it "parses 'friday' as last Friday" do
        result = instance.parse_date("friday")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 17, 0, 0, 0))
      end

      it "parses 'last friday' as last Friday" do
        result = instance.parse_date("last friday")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 17, 0, 0, 0))
      end

      it "parses 'monday' as today when today is Monday" do
        # On Monday, "monday" returns today (same as "today")
        result = instance.parse_date("monday")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 20, 0, 0, 0))
      end

      it "parses abbreviated day names" do
        result = instance.parse_date("fri")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 17, 0, 0, 0))
      end

      it "parses 'last monday' as previous Monday" do
        result = instance.parse_date("last monday")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 13, 0, 0, 0))
      end
    end

    describe "explicit dates" do
      it "parses YYYY-MM-DD format" do
        result = instance.parse_date("2025-01-15")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 15, 0, 0, 0))
      end

      it "parses other date formats" do
        result = instance.parse_date("January 15, 2025")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 15, 0, 0, 0))
      end
    end

    describe "case insensitivity" do
      it "handles uppercase" do
        result = instance.parse_date("TODAY")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 20, 0, 0, 0))
      end

      it "handles mixed case" do
        result = instance.parse_date("Friday")
        expect(Time.at(result)).to eq(Time.new(2025, 1, 17, 0, 0, 0))
      end
    end

    describe "error handling" do
      it "raises Thor::Error for invalid date" do
        expect { instance.parse_date("not a date") }.to raise_error(Thor::Error, /Could not parse date/)
      end
    end
  end

  describe "#filter_by_date" do
    let(:cards) do
      [
        OpenStruct.new(id: "1", time_created: 1737388800), # Jan 20, 2025 (Unix seconds)
        OpenStruct.new(id: "2", time_created: 1737302400), # Jan 19, 2025
        OpenStruct.new(id: "3", time_created: 1737216000), # Jan 18, 2025
        OpenStruct.new(id: "4", time_created: 1737388800000), # Jan 20 (milliseconds)
        OpenStruct.new(id: "5", time_created: nil)
      ]
    end

    it "filters items since a timestamp" do
      since = 1737302400 # Jan 19
      result = instance.filter_by_date(cards, field: :time_created, since: since)
      expect(result.map(&:id)).to contain_exactly("1", "2", "4")
    end

    it "handles millisecond timestamps" do
      since = 1737388800 # Jan 20
      result = instance.filter_by_date(cards, field: :time_created, since: since)
      expect(result.map(&:id)).to contain_exactly("1", "4")
    end

    it "excludes items with nil timestamps" do
      result = instance.filter_by_date(cards, field: :time_created, since: 0)
      expect(result.map(&:id)).not_to include("5")
    end

    it "filters with until_time" do
      since = 1737216000 # Jan 18
      until_time = 1737302400 # Jan 19
      result = instance.filter_by_date(cards, field: :time_created, since: since, until_time: until_time)
      expect(result.map(&:id)).to contain_exactly("2", "3")
    end
  end
end
