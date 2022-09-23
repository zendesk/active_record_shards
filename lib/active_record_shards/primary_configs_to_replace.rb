# frozen_string_literal: true

module ActiveRecordShards
  @@configs_to_replace_with_replicas = []

  class << self
    def configs_to_replace_with_replicas
      @@configs_to_replace_with_replicas.uniq
    end

    def replace_with_replica_configuration(*config_keys)
      config_keys.each do |key|
        @@configs_to_replace_with_replicas << key.to_s
      end
    end
  end
end
