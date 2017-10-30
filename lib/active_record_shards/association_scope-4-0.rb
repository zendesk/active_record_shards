module ActiveRecordShards
  module AssociationScope
    def self.included(base)
      base.send(:alias_method, :bind_without_default_shard, :bind)
      base.send(:alias_method, :bind, :bind_with_default_shard)
    end

    def bind_with_default_shard(scope, table_name, column_name, value, tracker)
      klass = scope.klass
      if klass.is_sharded? && klass.current_shard_id.nil? && table_name != ActiveRecord::SchemaMigration.table_name
        on_first_shard { bind_without_default_shard(scope, table_name, column_name, value, tracker) }
      else
        bind_without_default_shard(scope, table_name, column_name, value, tracker)
      end
    end
  end
end

ActiveRecord::Associations::AssociationScope.include(ActiveRecordShards::AssociationScope)
