# frozen_string_literal: true

require 'active_record'
require 'active_record/base'
require 'active_record_shards/configuration_parser'
require 'active_record_shards/model'
require 'active_record_shards/shard_selection'
require 'active_record_shards/connection_switcher'
require 'active_record_shards/association_collection_connection_selection'
require 'active_record_shards/migration'
require 'active_record_shards/default_replica_patches'
require 'active_record_shards/schema_dumper_extension'

module ActiveRecordShards
  def self.app_env
    env = Rails.env if defined?(Rails.env)
    env ||= RAILS_ENV if Object.const_defined?(:RAILS_ENV)
    env ||= ENV['RAILS_ENV']
    env ||= APP_ENV if Object.const_defined?(:APP_ENV)
    env ||= ENV['APP_ENV']
    env || 'development'
  end
end

ActiveRecord::Base.extend(ActiveRecordShards::ConfigurationParser)
ActiveRecord::Base.extend(ActiveRecordShards::Model)
ActiveRecord::Base.extend(ActiveRecordShards::ConnectionSwitcher)
ActiveRecord::Base.extend(ActiveRecordShards::DefaultReplicaPatches)
ActiveRecord::Relation.include(ActiveRecordShards::DefaultReplicaPatches::ActiveRelationPatches)
ActiveRecord::Associations::CollectionProxy.include(ActiveRecordShards::AssociationCollectionConnectionSelection)
ActiveRecord::Associations::Builder::HasAndBelongsToMany.include(ActiveRecordShards::DefaultReplicaPatches::HasAndBelongsToManyBuilderExtension)
ActiveRecord::SchemaDumper.prepend(ActiveRecordShards::SchemaDumperExtension)

# https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/type_caster/connection.rb#L28
ActiveRecord::TypeCaster::Connection.prepend(ActiveRecordShards::DefaultReplicaPatches::TypeCasterConnectionConnectionPatch)

# https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/schema.rb#L53-L54
ActiveRecord::Schema.prepend(ActiveRecordShards::DefaultReplicaPatches::SchemaDefinePatch)

# https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/relation.rb#L739
# But the #exec_queries and #compute_cache_version methods also call #connection, and I don't know if we should patch those, too...
ActiveRecord::Relation.prepend(ActiveRecordShards::DefaultReplicaPatches::RelationConnectionPatch)

# https://github.com/rails/rails/blob/v6.0.4/activerecord/lib/active_record/associations/association.rb#L213
ActiveRecord::Associations::Association.prepend(ActiveRecordShards::DefaultReplicaPatches::AssociationsAssociationFindTargetPatch)
