# frozen_string_literal: true

module Superthread
  # Shared timestamp utilities used across layers.
  module TimeUtils
    # Threshold for detecting millisecond timestamps vs second timestamps.
    # Timestamps above this value are assumed to be in milliseconds.
    MAX_SECONDS_TIMESTAMP = 9_999_999_999

    module_function

    # Normalizes a timestamp to seconds (API sometimes returns milliseconds).
    #
    # @param ts [Integer, nil] timestamp in seconds or milliseconds
    # @return [Integer, nil] timestamp in seconds, or nil if nil/zero
    def normalize_timestamp(ts)
      return nil if ts.nil? || ts == 0

      (ts > MAX_SECONDS_TIMESTAMP) ? ts / 1000 : ts
    end
  end
end
