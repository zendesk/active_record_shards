# frozen_string_literal: true

module ActiveRecordShards
  class ShardSupport
    class ShardEnumerator
      include Enumerable

      def each(&block)
        ActiveRecord::Base.on_all_shards(&block)
      end
    end

    def initialize(scope)
      @scope = scope
    end

    def enum
      ShardEnumerator.new
    end

    def find(*find_args)
      ensure_concrete!

      exception = nil
      enum.each do
        record = @scope.find(*find_args)
        return record if record
      rescue ActiveRecord::RecordNotFound => e
        exception = e
      end

      raise exception
    end

    ruby2_keywords(:find) if respond_to?(:ruby2_keywords, true)

    def count
      enum.inject(0) { |accum, _shard| @scope.clone.count + accum }
    end

    def to_a
      enum.flat_map { @scope.clone.to_a }
    end

    private

    def ensure_concrete!
      raise "Please call this method on a concrete model, not an abstract class!" if @scope.abstract_class?
    end
  end
end
