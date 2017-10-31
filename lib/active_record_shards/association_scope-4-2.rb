module ActiveRecordShards
  module AssociationScope
    def self.included(base)
      base.send(:alias_method, :bind_without_default_shard, :bind)
      base.send(:alias_method, :bind, :bind_with_default_shard)
    end

    def bind_with_default_shard(scope, *args)
      if scope.klass.needs_default_shard?
        scope.klass.on_first_shard { bind_without_default_shard(scope, *args) }
      else
        bind_without_default_shard(scope, *args)
      end
    end
  end
end

ActiveRecord::Associations::AssociationScope.include(ActiveRecordShards::AssociationScope)
