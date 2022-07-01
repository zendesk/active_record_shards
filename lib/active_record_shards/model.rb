# frozen_string_literal: true

module ActiveRecordShards
  module Model
    def not_sharded
      if self != ActiveRecord::Base && self != base_class
        raise "You should only call not_sharded on direct descendants of ActiveRecord::Base"
      end

      self.sharded = false
    end

    def is_sharded? # rubocop:disable Naming/PredicateName
      sharded != false
    end

    private

    attr_accessor :sharded
  end
end
