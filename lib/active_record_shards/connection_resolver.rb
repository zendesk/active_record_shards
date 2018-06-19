module ActiveRecordShards
  class ConnectionResolver
    attr_reader :configurations

    def initialize(configurations)
      @configurations = configurations
    end

    PRIMARY = "primary".freeze
    def resolve_connection_name(slave:, shard:, sharded:)
      resolved_shard = sharded ? shard : nil
      env = ActiveRecordShards.rails_env

      @connection_names ||= {}
      @connection_names[env] ||= {}
      @connection_names[env][resolved_shard] ||= {}
      @connection_names[env][resolved_shard][slave] ||= begin
        name = env.dup
        name << "_shard_#{resolved_shard}" if resolved_shard
        if slave && configurations["#{name}_slave"]
          "#{name}_slave"
        else
          # ActiveRecord always names its default connection pool 'primary'
          # while everything else is named by the configuration name
          resolved_shard ? name : PRIMARY
        end
      end
    end
  end
end
