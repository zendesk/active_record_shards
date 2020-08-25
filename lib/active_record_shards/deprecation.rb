module ActiveRecordShards
  class Deprecation < ActiveSupport::Deprecation
    # This allows us to define separate deprecation behavior for ActiveRecordShards, but defaults to
    # the same behavior globally configured with ActiveSupport.
    #
    # For example, this allows us to silence our own deprecation warnings in test while still being
    # able to fail tests for upstream deprecation warnings.
    def behavior
      @behavior ||= ActiveSupport::Deprecation.behavior
    end
  end
end
